require! {
  '../support/dim-console'
  'chai' : {expect}
  'exocomm-mock' : ExoCommMock
  'exoservice' : ExoService
  'jsdiff-console'
  'livescript'
  'nitroglycerin' : N
  'port-reservation'
  'record-http' : HttpRecorder
  'request'
  '../support/remove-ids' : {remove-ids}
  'wait' : {wait-until}
}


module.exports = ->

  @Given /^an ExoComm server$/, (done) ->
    port-reservation
      ..get-port N (@exocomm-port) ~>
        @exocomm = new ExoCommMock
          ..listen @exocomm-port, done


  @Given /^an instance of this service$/, (done) ->
    port-reservation
      ..get-port N (@service-port) ~>
        @exocomm.register-service name: 'users', port: @service-port
        @process = new ExoService service-name: 'users', exocomm-port: @exocomm.port, exorelay-port: @service-port
          ..listen!
          ..on 'online', -> done!


  @Given /^the service contains the users:$/, (table, done) ->
    users = [{[key.to-lower-case!, value] for key, value of record} for record in table.hashes!]
    @exocomm
      ..send-message service: 'users', name: 'users.create-many', payload: users
      ..wait-until-receive done



  @When /^sending the message "([^"]*)"$/, (message) ->
    @exocomm
      ..send-message service: 'users', name: message


  @When /^sending the message "([^"]*)" with the payload:$/, (message, payload) ->
    eval livescript.compile "payload-json = {\n#{payload}\n}", bare: true, header: no
    @exocomm
      ..send-message service: 'users', name: message, payload: payload-json


  @Then /^the service contains no users$/, (done) ->
    @exocomm
      ..send-message service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        expect(@exocomm.received-messages![0].payload.count).to.equal 0
        done!


  @Then /^the service contains the user accounts:$/, (table, done) ->
    @exocomm
      ..send-message service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        actual-users = remove-ids @exocomm.received-messages![0].payload.users
        expected-users = [{[key.to-lower-case!, value] for key, value of user} for user in table.hashes!]
        jsdiff-console actual-users, expected-users, done


  @Then /^the service replies with "([^"]*)" and the payload:$/, (message, payload, done) ->
    @exocomm.wait-until-receive ~>
      actual-payload = @exocomm.received-messages![0].payload
      eval livescript.compile "expected-payload = {\n#{payload}\n}", bare: yes, header: no
      jsdiff-console remove-ids(actual-payload), remove-ids(expected-payload), done
