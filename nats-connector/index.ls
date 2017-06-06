require! {
  'nats': NATS
  'prelude-ls': {each, obj-to-pairs}
}

class NatsConnector

  ->
    @nats = NATS.connect "nats://#{process.env.NATS_HOST}:4222"
    console.log "connected to nats"

  subscribeMapping: (messageCallbackMapping) ->
    messageCallbackMapping |> obj-to-pairs |> each ([name, callback]) ~>
      @nats.subscribe name, (request, replyTo) ~>
        callback request.payload, reply: (payload) ~> @nats.publish replyTo, payload

  send: (name, data, callback) ->
    @nats.request name, data, {max: 1}, (response) ->
      callback response.payload


module.exports = NatsConnector
