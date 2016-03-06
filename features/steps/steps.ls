require! {
  'chai' : {expect}
  'dim-console'
  'exocom-mock' : ExoComMock
  'exoservice' : ExoService
  'jsdiff-console'
  'livescript'
  'nitroglycerin' : N
  'port-reservation'
  'record-http' : HttpRecorder
  'request'
  'wait' : {wait-until}
}


module.exports = ->

  @Given /^an ExoCom server$/, (done) ->
    port-reservation
      ..get-port N (@exocom-port) ~>
        @exocom = new ExoComMock
          ..listen @exocom-port, done


  @Given /^an instance of this service$/, (done) ->
    port-reservation
      ..get-port N (@service-port) ~>
        @exocom.register-service name: 'users', port: @service-port
        @process = new ExoService service-name: 'users', exocom-port: @exocom.port, exorelay-port: @service-port
          ..listen!
          ..on 'online', -> done!


  @Given /^the service contains the users:$/, (table, done) ->
    users = [{[key.to-lower-case!, value] for key, value of record} for record in table.hashes!]
    @exocom
      ..send-message service: 'users', name: 'users.create-many', payload: users
      ..wait-until-receive done



  @When /^sending the message "([^"]*)"$/, (message) ->
    @exocom
      ..send-message service: 'users', name: message


  @When /^sending the message "([^"]*)" with the payload:$/, (message, payload) ->
    if payload[0] is '['
      eval livescript.compile "payload-json = #{payload}", bare: true, header: no
    else
      eval livescript.compile "payload-json = {\n#{payload}\n}", bare: true, header: no
    @exocom
      ..send-message service: 'users', name: message, payload: payload-json


  @When /^sending the message "([^"]*)" with the id of (.+)$/, (message, user-name, done) ->
    @exocom
      ..send-message service: 'users', name: 'user.get-details', payload: {name: user-name}
      ..wait-until-receive ~>
        id = @exocom.received-messages![0].payload.id
        @exocom.send-message service: 'users', name: 'user.get-details', payload: {id}
        done!



  @Then /^the service contains no users$/, (done) ->
    @exocom
      ..send-message service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        expect(@exocom.received-messages![0].payload.count).to.equal 0
        done!


  @Then /^the service contains the user accounts:$/, (table, done) ->
    @exocom
      ..send-message service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        actual-users = @remove-ids @exocom.received-messages![0].payload.users
        expected-users = [{[key.to-lower-case!, value] for key, value of user} for user in table.hashes!]
        jsdiff-console actual-users, expected-users, done


  @Then /^the service replies with "([^"]*)" and the payload:$/, (message, payload, done) ->
    eval livescript.compile "expected-payload = {\n#{payload}\n}", bare: yes, header: no
    @exocom.wait-until-receive ~>
      actual-payload = @exocom.received-messages![0].payload
      jsdiff-console @remove-ids(actual-payload), @remove-ids(expected-payload), done
