package main

import (
	"fmt"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"github.com/Originate/exocom/go/exorelay"
	"github.com/Originate/exocom/go/exoservice"
)

func handleCreate(request exoservice.Request) {
	data, ok := request.Payload.(map[string]interface{})
	if !ok {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-created",
			Payload: map[string]interface{}{"error": "Invalid payload: should be an object"},
		})
		return
	}
	if data["content"] == "" {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-created",
			Payload: map[string]interface{}{"error": "Content cannot be blank"},
		})
		return
	}
	id := bson.NewObjectId()
	newTweet := map[string]interface{}{
		"_id":      id,
		"content":  data["content"],
		"owner_id": data["owner_id"],
	}
	err := collection.Insert(newTweet)
	if err != nil {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-created",
			Payload: map[string]interface{}{"error": err.Error()},
		})
		return
	}
	request.Reply(exorelay.MessageOptions{
		Name: "tweets.created",
		Payload: map[string]interface{}{
			"id":       string(id.Hex()),
			"content":  newTweet["content"],
			"owner_id": newTweet["owner_id"],
		},
	})
}

func handleDelete(request exoservice.Request) {
	data, ok := request.Payload.(map[string]interface{})
	if !ok {
		fmt.Println("not okay")
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": "Invalid payload: should be an object"},
		})
		return
	}
	if !bson.IsObjectIdHex(data["id"].(string)) {
		fmt.Println("invalid id")
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": "Invalid id"},
		})
		return
	}
	id := bson.ObjectIdHex(data["id"].(string))
	fmt.Println(id)
	var result map[string]interface{}
	err := collection.FindId(id).One(result)
	if err != nil {
		fmt.Println("find failed")
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": err.Error()},
		})
		return
	}
	err = collection.Remove(bson.M{"_id": id})
	if err != nil {
		fmt.Println("remove failed")
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": err.Error()},
		})
		return
	}
	fmt.Println(result)
	request.Reply(exorelay.MessageOptions{
		Name: "tweets.deleted",
		Payload: map[string]interface{}{
			"id":       string(result["_id"].(bson.ObjectId).Hex()),
			"content":  result["content"],
			"owner_id": result["owner_id"],
		},
	})
}

func handleCreateMany(request exoservice.Request) {
	items, ok := request.Payload.([]interface{})
	if !ok {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-created-many",
			Payload: map[string]interface{}{"error": "Invalid payload: should be an array"},
		})
	}
	newTweets := make([]interface{}, len(items), len(items))
	for index, item := range items {
		data, ok := item.(map[string]interface{})
		if !ok {
			request.Reply(exorelay.MessageOptions{
				Name:    "tweets.not-created-many",
				Payload: map[string]interface{}{"error": fmt.Sprintf("Invalid payload[%d]: should be an object", index)},
			})
			return
		}
		if data["content"] == "" {
			request.Reply(exorelay.MessageOptions{
				Name:    "tweets.not-created-many",
				Payload: map[string]interface{}{"error": "Content cannot be blank"},
			})
			return
		}
		newTweets[index] = map[string]interface{}{"content": data["content"]}
	}
	err := collection.Insert(newTweets...)
	if err != nil {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-created-many",
			Payload: map[string]interface{}{"error": err.Error()},
		})
		return
	}
	request.Reply(exorelay.MessageOptions{
		Name:    "tweets.created-many",
		Payload: map[string]interface{}{"count": len(items)},
	})
}

func handleGetDetails(request exoservice.Request) {
	input, ok := request.Payload.(map[string]interface{})
	if !ok {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": "Invalid payload: should be an object"},
		})
		return
	}
	query := map[string]interface{}{}
	for k, v := range input {
		if k == "id" {
			if !bson.IsObjectIdHex(v.(string)) {
				request.Reply(exorelay.MessageOptions{
					Name:    "tweets.not-found",
					Payload: map[string]interface{}{"error": "Invalid id"},
				})
				return
			}
			query["_id"] = bson.ObjectIdHex(v.(string))
		} else {
			query[k] = v
		}
	}
	result := map[string]interface{}{}
	err := collection.Find(query).One(&result)
	if err != nil {
		request.Reply(exorelay.MessageOptions{
			Name:    "tweets.not-found",
			Payload: map[string]interface{}{"error": err.Error()},
		})
		return
	}
	request.Reply(exorelay.MessageOptions{
		Name: "tweets.details",
		Payload: map[string]interface{}{
			"id":       string(result["_id"].(bson.ObjectId).Hex()),
			"content":  result["content"],
			"owner_id": result["owner_id"],
		},
	})
}

var collection *mgo.Collection

func main() {
	mongoSession, err := mgo.Dial("mongodb://localhost/")
	if err != nil {
		panic(err)
	}
	collection = mongoSession.DB("space-tweet-tweets-test").C("tweets")
	messageHandlers := exoservice.MessageHandlerMapping{
		"tweets.create-many": handleCreateMany,
		"tweets.create":      handleCreate,
		"tweets.delete":      handleDelete,
		"tweets.get-details": handleGetDetails,
	}
	exoservice.Bootstrap(messageHandlers)
}
