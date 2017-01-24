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
}


start-exorelay = (done) ->
  global.exorelay = new ExoRelay role: process.env.ROLE, exocom-port: process.env.EXOCOM_PORT, exocom-host: process.env.EXOCOM_HOST
    ..connect!
    ..on 'error', (err) -> console.log red err
    ..on 'online', ->
      console.log "#{green 'ExoRelay'} online"
      done!


start-web-server = (done) ->
  web-server = new WebServer
    ..on 'error', (err) -> console.log red err
    ..on 'listening', ->
      console.log "#{green 'HTML server'} online at port #{cyan web-server.port!}"
      done!
    ..listen 3000


start-exorelay N ->
  start-web-server N ->
    console.log green 'all systems go'
