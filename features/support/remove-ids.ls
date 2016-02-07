remove-ids = (payload) ->
  for key, value of payload
    if key is 'id'
      delete payload[key]
    else if typeof value is 'object'
      payload[key] = remove-ids value
    else if typeof value is 'array'
      payload[key] = [remove-ids(child) for child in value]
  payload




module.exports = {remove-ids}
