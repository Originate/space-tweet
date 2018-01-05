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
      EXOCOM_PORT: @exocomPort
      EXOCOM_HOST: 'localhost'
      ROLE: 'users'
    stdout: devNull()
    stderr: devNull()
  })
  wait-until (~> @exocom.knows-service 'users'), 50, done


Given /^the service contains the users:$/, (table, done) ->
  users = table.hashes! |> map lowercase-keys
  @exocom
    ..send service: 'users', name: 'create many users', payload: users
    ..on-receive done



When /^sending the message "([^"]*)"$/, (message) ->
  @exocom.send service: 'users', name: message


When /^sending the message "([^"]*)" with the payload:$/, (message, payload, done) ->
  @fill-in-user-ids payload, (filled-payload) ~>
    if filled-payload[0] is '['   # payload is an array
      eval livescript.compile "payload-json = #{filled-payload}", bare: true, header: no
    else                          # payload is a hash
      eval livescript.compile "payload-json = {\n#{filled-payload}\n}", bare: true, header: no
    @exocom.send service: 'users', name: message, payload: payload-json
    done!



Then /^the service contains no users$/, (done) ->
  @exocom
    ..send service: 'users', name: 'list users'
    ..on-receive ~>
      expect(@exocom.received-messages[0].payload.count).to.equal 0
      done!


Then /^the service now contains the users:$/, (table, done) ->
  @exocom
    ..send service: 'users', name: 'list users'
    ..on-receive ~>
      actual-users = @remove-ids @exocom.received-messages[0].payload.users
      expected-users = table.hashes! |> map lowercase-keys
      expect(actual-users).to.eql expected-users
      done!


Then /^the service replies with "([^"]*)" and the payload:$/, (message, payload, done) ->
  eval livescript.compile "expected-payload = {\n#{payload}\n}", bare: yes, header: no
  @exocom.on-receive ~>
    actual-payload = @exocom.received-messages[0].payload
    expect(@remove-ids(actual-payload)).to.eql @remove-ids(expected-payload)
    done!
