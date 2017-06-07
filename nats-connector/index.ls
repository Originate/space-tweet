require! {
  'nats': NATS
  'prelude-ls': {each, obj-to-pairs}
  'util'
}

class NatsConnector

  ->
    @nats = NATS.connect "nats://#{process.env.NATS_HOST}:4222"
    console.log "nats: connected"


  subscribeMapping: (messageCallbackMapping) ->
    messageCallbackMapping |> obj-to-pairs |> each ([name, callback]) ~>
      @nats.subscribe name, (requestDataStr, replyTo) ~>
        requestData = JSON.parse requestDataStr
        @_log 'received request for', name, requestData
        callback requestData, reply: (replyData) ~>
          @_log 'responding to', name, replyData
          @nats.publish replyTo, JSON.stringify(replyData)


  send: (name, requestData, callback) ->
    @_log 'requesting', name, requestData
    @nats.request name, JSON.stringify(requestData), {max: 1}, (responseDataStr) ~>
      responseData = JSON.parse responseDataStr
      @_log 'received response to', name, responseData
      callback responseData


  _log: (prefix, name, data) ->
    console.log 'nats:', prefix, name, 'with payload:', util.inspect data, breakLength: Infinity


module.exports = NatsConnector
