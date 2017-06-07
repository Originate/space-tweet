require! {
  './server' : server
  '../nats-connector': NatsConnector
}

natsConnector = new NatsConnector()
server.before-all ->
  delete server.before-all
  natsConnector.subscribeMapping server
