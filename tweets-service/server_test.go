package main_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"reflect"
	"strings"
	"testing"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
	yaml "gopkg.in/yaml.v2"

	"github.com/DATA-DOG/godog"
	"github.com/DATA-DOG/godog/gherkin"
	"github.com/Originate/exocom/go/exocom-mock"
	"github.com/Originate/exocom/go/structs"
)

type ServiceConfig struct {
	Type string `yaml:type`
}

func getServiceConfig() (*ServiceConfig, error) {
	config := &ServiceConfig{}
	configBytes, err := ioutil.ReadFile("service.yml")
	if err != nil {
		return nil, fmt.Errorf("Error reading service.yml", err)
	}
	err = yaml.Unmarshal(configBytes, &config)
	if err != nil {
		return nil, fmt.Errorf("Error unmarshaling service.yml", err)
	}
	return config, nil
}

func getRole() (string, error) {
	config, err := getServiceConfig()
	if err != nil {
		return "", err
	}
	return config.Type, nil
}

func newExocomMock(port int) *exocomMock.ExoComMock {
	exocom := exocomMock.New()
	go func() {
		err := exocom.Listen(port)
		if err != nil && err != http.ErrServerClosed {
			panic(fmt.Errorf("Error listening on exocom", err))
		}
	}()
	return exocom
}

func tableToHashes(table *gherkin.DataTable) []map[string]string {
	var keys []string
	result := make([]map[string]string, len(table.Rows)-1, len(table.Rows)-1)
	for rowIndex, row := range table.Rows {
		if rowIndex == 0 {
			keys = make([]string, len(row.Cells), len(row.Cells))
			for cellIndex, cell := range row.Cells {
				keys[cellIndex] = strings.ToLower(cell.Value)
			}
		} else {
			result[rowIndex-1] = map[string]string{}
			for cellIndex, cell := range row.Cells {
				result[rowIndex-1][keys[cellIndex]] = cell.Value
			}
		}
	}
	return result
}

func FeatureContext(s *godog.Suite) {
	var exocom *exocomMock.ExoComMock
	var role string
	var serviceCommand *exec.Cmd
	var serviceCommandStdout, serviceCommandStderr io.ReadCloser
	var collection *mgo.Collection
	port := 4100

	s.BeforeSuite(func() {
		var err error
		exocom = newExocomMock(port)
		role, err = getRole()
		if err != nil {
			panic(err)
		}
		mongoSession, err := mgo.Dial("mongodb://localhost/")
		if err != nil {
			panic(err)
		}
		collection = mongoSession.DB("space-tweet-tweets-test").C("tweets")
	})

	s.BeforeScenario(func(arg1 interface{}) {
		serviceCommand = nil
	})

	s.AfterScenario(func(interface{}, error) {
		exocom.Reset()
		if serviceCommand != nil {
			err := serviceCommand.Process.Kill()
			if err != nil {
				panic(fmt.Errorf("Error when killing the service command: %v", err))
			}
			if os.Getenv("DEBUG") != "" {
				stdout, err := ioutil.ReadAll(serviceCommandStdout)
				if err != nil {
					panic(fmt.Errorf("Error reading stdout for service command: %v", err))
				}
				fmt.Println(string(stdout))
			}
			stderr, err := ioutil.ReadAll(serviceCommandStderr)
			if err != nil {
				panic(fmt.Errorf("Error reading stderr for service command: %v", err))
			}
			if len(stderr) > 0 {
				panic(fmt.Errorf("Service command printed to stderr: %s", stderr))
			}
		}
		collection.RemoveAll(nil)
	})

	s.AfterSuite(func() {
		err := exocom.Close()
		if err != nil {
			panic(fmt.Errorf("Error closing exocom", err))
		}
	})

	s.Step(`^an instance of this service$`, func() error {
		serviceCommand = exec.Command("go", "run", "server.go")
		env := os.Environ()
		env = append(env, fmt.Sprintf("EXOCOM_PORT=%d", port), fmt.Sprintf("ROLE=%d", role))
		serviceCommand.Env = env
		var err error
		serviceCommandStdout, err = serviceCommand.StdoutPipe()
		if err != nil {
			return err
		}
		serviceCommandStderr, err = serviceCommand.StderrPipe()
		if err != nil {
			return err
		}
		err = serviceCommand.Start()
		if err != nil {
			return err
		}
		return exocom.WaitForConnection()
	})

	s.Step(`^sending the message "([^"]*)"$`, func(name string) error {
		message := structs.Message{Name: name}
		err := exocom.WaitForConnection()
		if err != nil {
			return err
		}
		return exocom.Send(message)
	})

	s.Step(`^sending the message "([^"]*)" with the payload:$`, func(name string, payloadStr *gherkin.DocString) error {
		t := template.New("request")
		t.Funcs(template.FuncMap{
			"idOf": func(content string) (string, error) {
				var result map[string]interface{}
				err := collection.Find(bson.M{"content": content}).One(&result)
				if err != nil {
					return "", err
				}
				if result == nil {
					return "", fmt.Errorf("Could not find id for tweet with content: %s", content)
				}
				return result["_id"].(bson.ObjectId).Hex(), nil
			},
		})
		t, err := t.Parse(payloadStr.Content)
		if err != nil {
			return err
		}
		var payloadBuffer bytes.Buffer
		err = t.Execute(&payloadBuffer, nil)
		if err != nil {
			return err
		}
		var payload structs.MessagePayload
		err = json.Unmarshal(payloadBuffer.Bytes(), &payload)
		if err != nil {
			return err
		}
		message := structs.Message{
			Name:    name,
			Payload: payload,
		}
		err = exocom.WaitForConnection()
		if err != nil {
			return err
		}
		return exocom.Send(message)
	})

	s.Step(`^the service replies with "([^"]*)" and the payload:$`, func(expectedName string, payloadStr *gherkin.DocString) error {
		t := template.New("request")
		t.Funcs(template.FuncMap{
			"idOf": func(content string) (string, error) {
				var result map[string]interface{}
				err := collection.Find(bson.M{"content": content}).One(&result)
				if err != nil {
					return "", err
				}
				if result == nil {
					return "", fmt.Errorf("Could not find id for tweet with content: %s", content)
				}
				return result["_id"].(bson.ObjectId).Hex(), nil
			},
		})
		t, err := t.Parse(payloadStr.Content)
		if err != nil {
			return err
		}
		var expectedPayloadBuffer bytes.Buffer
		err = t.Execute(&expectedPayloadBuffer, nil)
		if err != nil {
			return err
		}
		var expectedPayload structs.MessagePayload
		err = json.Unmarshal(expectedPayloadBuffer.Bytes(), &expectedPayload)
		if err != nil {
			return err
		}
		actualMessage, err := exocom.WaitForMessageWithName(expectedName)
		if err != nil {
			return err
		}
		if !reflect.DeepEqual(actualMessage.Payload, expectedPayload) {
			return fmt.Errorf("Expected message to have name %v but got %v", expectedPayload, actualMessage.Payload)
		}
		return nil
	})

	s.Step(`^the service contains no entries$`, func() error {
		count, err := collection.Count()
		if err != nil {
			return err
		}
		if count != 0 {
			return fmt.Errorf("Expected count to be 0 but got %d", count)
		}
		return nil
	})

	s.Step(`^the service now contains the entries:$`, func(table *gherkin.DataTable) error {
		expected := tableToHashes(table)
		var actual []map[string]string
		err := collection.Find(nil).All(&actual)
		if err != nil {
			return err
		}
		for _, item := range actual {
			delete(item, "_id")
		}
		if !reflect.DeepEqual(actual, expected) {
			return fmt.Errorf("Expected entries to be %v but got %v", expected, actual)
		}
		return nil
	})

	s.Step(`^the service contains the entries:$`, func(table *gherkin.DataTable) error {
		err := exocom.Send(structs.Message{
			Name:    "tweets.create-many",
			Payload: tableToHashes(table),
		})
		if err != nil {
			return err
		}
		_, err = exocom.WaitForMessageWithName("tweets.created-many")
		return err
	})
}

func TestMain(m *testing.M) {
	var paths []string
	var format string
	if len(os.Args) == 3 && os.Args[1] == "--" {
		format = "pretty"
		paths = append(paths, os.Args[2])
	} else {
		format = "progress"
		paths = append(paths, "features")
	}
	status := godog.RunWithOptions("godogs", func(s *godog.Suite) {
		FeatureContext(s)
	}, godog.Options{
		Format:        format,
		NoColors:      false,
		StopOnFailure: true,
		Paths:         paths,
	})

	os.Exit(status)
}
