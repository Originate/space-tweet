const eco = require('eco')
const { setWorldConstructor } = require('cucumber')

class World {
  // Fills in entry ids in the placeholders of the template
  fillInEntryIds(template, done) {
    const neededIds = []
    eco.render(template, {
      id_of: entry => neededIds.push(entry),
    })
    if (neededIds.length === 0) {
      done(template)
      return
    }
    this.exocom.send({
      service: 'tweets',
      name: 'get tweet details',
      payload: { content: neededIds[0] },
    })
    this.exocom.onReceive(() => {
      const { id } = this.exocom.receivedMessages[0].payload
      done(eco.render(template, { id_of: () => id }))
    })
  }

  removeIds(payload) {
    if (Array.isArray(payload)) {
      return payload.map(v => this.removeIds(v))
    }
    const result = { ...payload }
    Object.entries(result).forEach(([key, value]) => {
      if (key === 'id') {
        delete result[key]
      } else if (Array.isArray(value)) {
        result[key] = value.map(v => this.removeIds(v))
      } else if (typeof value === 'object') {
        result[key] = this.removeIds(value)
      }
    })
    return result
  }
}

setWorldConstructor(World)
