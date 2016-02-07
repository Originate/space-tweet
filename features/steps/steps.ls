require! {
  '../support/dim-console'
  'chai' : {expect}
  'exocomm-mock' : ExoCommMock
  'exoservice' : ExoService
  'jsdiff-console'
  'livescript'
  'nitroglycerin' : N
  'observable-process' : ObservableProcess
  'portfinder'
  'record-http' : HttpRecorder
  'request'
  '../support/remove-ids' : {remove-ids}
  'wait' : {wait-until}
}


module.exports = ->

  @Given /^an ExoComm server$/, (done) ->
    portfinder
      ..base-port = 4100
      ..get-port N (@exocomm-port) ~>
        @exocomm = new ExoCommMock
          ..listen @exocomm-port, done


  @Given /^an instance of this service$/, (done) ->
    portfinder
      ..base-port = 4000
      ..get-port N (@service-port) ~>
        @exocomm.register-service name: 'users', port: @service-port
        @process = new ExoService exocomm-port: @exocomm.port
          ..listen port: @service-port
          ..on 'online', -> done!


  @Given /^the service contains the users:$/, (table, done) ->
    users = [{[key.to-lower-case!, value] for key, value of record} for record in table.hashes!]
    @exocomm
      ..send-command service: 'users', name: 'users.create-many', payload: users
      ..wait-until-receive done



  @When /^sending the command "([^"]*)"$/, (command) ->
    @exocomm
      ..send-command service: 'users', name: command


  @When /^sending the command "([^"]*)" with the payload:$/, (command, payload) ->
    eval livescript.compile "payload-json = {\n#{payload}\n}", bare: true, header: no
    @exocomm
      ..send-command service: 'users', name: command, payload: payload-json


  @Then /^the service contains no users$/, (done) ->
    @exocomm
      ..send-command service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        expect(@exocomm.received-commands![0].payload.count).to.equal 0
        done!


  @Then /^the service contains the user accounts:$/, (table, done) ->
    @exocomm
      ..send-command service: 'users', name: 'users.list'
      ..wait-until-receive ~>
        actual-users = remove-ids @exocomm.received-commands![0].payload.users
        expected-users = [{[key.to-lower-case!, value] for key, value of user} for user in table.hashes!]
        jsdiff-console actual-users, expected-users, done


  @Then /^the service replies with "([^"]*)" and the payload:$/, (command, payload, done) ->
    @exocomm.wait-until-receive ~>
      actual-payload = @exocomm.received-commands![0].payload
      eval livescript.compile "expected-payload = {\n#{payload}\n}", bare: yes, header: no
      jsdiff-console remove-ids(actual-payload), remove-ids(expected-payload), done
