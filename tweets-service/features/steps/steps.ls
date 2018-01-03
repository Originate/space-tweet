require! {
  'chai' : {expect}
  'cucumber': {Given, When, Then}
  'dev-null': devNull
  'exocom-mock' : ExoComMock
  'fs'
  'js-yaml': yaml
  'livescript'
  'lowercase-keys'
  'nitroglycerin' : N
  'observable-process': ObservableProcess
  'port-reservation'
  'prelude-ls' : {map}
  'wait' : {wait-until, wait}
}


serviceConfig = yaml.safeLoad fs.readFileSync('service.yml'), 'utf8'


Given /^an ExoCom server$/, (done) ->
  port-reservation
    ..get-port N (@exocom-port) ~>
      @exocom = new ExoComMock
        ..listen @exocom-port
      done!


Given /^an instance of this service$/, (done) ->
  @process = new ObservableProcess({
    command: serviceConfig.development.scripts.run
    env:
      EXOCOM_PORT: @exocom-port
      EXOCOM_HOST: 'localhost'
      ROLE: 'tweets'
    stdout: devNull()
    stderr: devNull()
  })
  wait-until (~> @exocom.knows-service 'tweets'), 10, done


Given /^the service contains the entries:$/, (table, done) ->
  entries = table.hashes! |> map lowercase-keys
  @exocom
    ..send service: 'tweets', name: 'create many tweets', payload: entries
    ..on-receive done



When /^sending the message "([^"]*)"$/, (message) ->
  @exocom.send service: 'tweets', name: message


When /^sending the message "([^"]*)" with the payload:$/, (message, payload, done) ->
  @fill-in-entry-ids payload, (filled-payload) ~>
    if filled-payload[0] is '['   # payload is an array
      eval livescript.compile "payload-json = #{filled-payload}", bare: true, header: no
    else                          # payload is a hash
      eval livescript.compile "payload-json = {\n#{filled-payload}\n}", bare: true, header: no
    @exocom.send service: 'tweets', name: message, payload: payload-json
    done!



Then /^the service contains no entries/, (done) ->
  @exocom
    ..send service: 'tweets', name: 'list tweets', payload: { owner_id: '1' }
    ..on-receive ~>
      expect(@exocom.received-messages[0].payload.count).to.equal 0
      done!


Then /^the service now contains the entries:$/, (table, done) ->
  @exocom
    ..send service: 'tweets', name: 'list tweets', payload: { owner_id: '1' }
    ..on-receive ~>
      actual-entries = @remove-ids @exocom.received-messages[0].payload.entries
      expected-entries = table.hashes! |> map lowercase-keys
      expect(actual-entries).to.eql expected-entries
      done!


Then /^the service replies with "([^"]*)" and the payload:$/, (message, payload, done) ->
  eval livescript.compile "expected-payload = {\n#{payload}\n}", bare: yes, header: no
  @exocom.on-receive ~>
    actual-payload = @exocom.received-messages[0].payload
    expect(@remove-ids(actual-payload)).to.eql @remove-ids(expected-payload)
    done!
