require! {
  'nats': NATS
}

class NatsConnector

  constructor: ->
    @nats = NATS.connect "nats://#{process.env.NATS_IO_HOST}:#{process.env.NATS_IO_PORT}"
    console.log "connected to nats"

  subscribeMapping: (messageCallbackMapping) ->
    methods |> obj-to-pairs |> List.each ([name, callback]) ~>
      @nats.subscribe name, (request, replyTo) ~>
        callbak request.payload, reply: (payload) ~> @nats.publish replyTo, payload

  send: (name, data, callback) ->
    @nats.requestOne name, data, (response) ->
      callback response.payload


module.exports = NatsConnector
