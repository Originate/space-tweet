# This is the main server file.
#
# It parses the command line and instantiates the two servers for this app:
require! {
  'async'
  'chalk' : {cyan, dim, green, red}
  'exorelay' : ExoRelay
  'nitroglycerin' : N
  '../package.json' : {name, version}
  './web-server' : WebServer
  '../nats-connector': NatsConnector
}


start-web-server = (done) ->
  natsConnector = new NatsConnector()
  web-server = new WebServer {send: natsConnector.send.bind(natsConnector)}
    ..on 'error', (err) -> console.log red err
    ..on 'listening', ->
      console.log "#{green 'HTML server'} online at port #{cyan web-server.port!}"
      done!
    ..listen 3000


start-web-server N ->
  console.log green 'all systems go'
