/* eslint-disable func-names */
const fs = require('fs')
const { expect } = require('chai')
const { Given, When, Then } = require('cucumber')
const devNull = require('dev-null')
const ExoComMock = require('exocom-mock')
const yaml = require('js-yaml')
const lowercaseKeys = require('lowercase-keys')
const N = require('nitroglycerin')
const ObservableProcess = require('observable-process')
const portReservation = require('port-reservation')
const { waitUntil } = require('wait')

const serviceConfig = yaml.safeLoad(fs.readFileSync('service.yml'), 'utf8')

Given(/^an ExoCom server$/, function(done) {
  portReservation.getPort(
    N(port => {
      this.exocomPort = port
      this.exocom = new ExoComMock()
      this.exocom.listen(port)
      done()
    })
  )
})

Given(/^an instance of this service$/, function(done) {
  this.process = new ObservableProcess({
    command: serviceConfig.development.scripts.run,
    env: {
      EXOCOM_PORT: this.exocomPort,
      EXOCOM_HOST: 'localhost',
      ROLE: 'tweets',
    },
    stdout: devNull(),
    stderr: devNull(),
  })
  waitUntil(() => this.exocom.knowsService('tweets'), 10, done)
})

Given(/^the service contains the entries:$/, function(table, done) {
  const entries = table.hashes().map(lowercaseKeys)
  this.exocom.send({
    service: 'tweets',
    name: 'create many tweets',
    payload: entries,
  })
  this.exocom.onReceive(done)
})

When(/^sending the message "([^"]*)"$/, function(message) {
  this.exocom.send({ service: 'tweets', name: message })
})

When(/^sending the message "([^"]*)" with the payload:$/, function(
  message,
  payloadStr,
  done
) {
  this.fillInEntryIds(payloadStr, filledPayloadStr => {
    const payload = JSON.parse(filledPayloadStr)
    this.exocom.send({ service: 'tweets', name: message, payload })
    done()
  })
})

Then(/^the service contains no entries/, function(done) {
  this.exocom.send({
    service: 'tweets',
    name: 'list tweets',
    payload: { owner_id: '1' },
  })
  this.exocom.onReceive(() => {
    expect(this.exocom.receivedMessages[0].payload.count).to.equal(0)
    done()
  })
})

Then(/^the service now contains the entries:$/, function(table, done) {
  this.exocom.send({
    service: 'tweets',
    name: 'list tweets',
    payload: { owner_id: '1' },
  })
  this.exocom.onReceive(() => {
    const actualEntries = this.removeIds(
      this.exocom.receivedMessages[0].payload.entries
    )
    const expectedEntries = table.hashes().map(lowercaseKeys)
    expect(actualEntries).to.eql(expectedEntries)
    done()
  })
})

Then(/^the service replies with "([^"]*)"$/, function(message, done) {
  this.exocom.onReceive(() => {
    const actualName = this.exocom.receivedMessages[0].name
    expect(actualName).to.eql(message)
    done()
  })
})

Then(/^the service replies with "([^"]*)" and the payload:$/, function(
  message,
  payloadStr,
  done
) {
  const expectedPayload = JSON.parse(payloadStr)
  this.exocom.onReceive(() => {
    const receivedMessage = this.exocom.receivedMessages[0]
    expect(receivedMessage.name).to.eql(message)
    expect(this.removeIds(receivedMessage.payload)).to.eql(
      this.removeIds(expectedPayload)
    )
    done()
  })
})
