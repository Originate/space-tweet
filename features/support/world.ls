require! {
  'eco'
}


World = !->

  # Fills in entry ids in the placeholders of the template
  @fill-in-entry-ids = (template, done) ->
    needed-ids = []
    eco.render template, id_of: (entry) -> needed-ids.push entry
    return done template if needed-ids.length is 0
    @exocom
      ..send service: 'tweets', name: 'tweets.get-details', payload: {content: needed-ids[0]}
      ..on-receive ~>
        id = @exocom.received-messages[0].payload.id
        done eco.render(template, id_of: (entry) -> id)


  @remove-ids = (payload) ->
    for key, value of payload
      if key is 'id'
        delete payload[key]
      else if typeof value is 'object'
        payload[key] = @remove-ids value
      else if typeof value is 'array'
        payload[key] = [@remove-ids(child) for child in value]
    payload



module.exports = ->
  @World = World
