require! {
  './server' : server
  '../nats-connector': NatsConnector
}

natsConnector = new NatsConnector()
server.before-all ->
  delete subscribeMapping.before-all
  natsConnector.subscribeMapping server
