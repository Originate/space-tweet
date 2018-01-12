const { ObjectID } = require('mongodb')

const idToMongo = function(query) {
  const result = { ...query }
  if (result.id) {
    result._id = new ObjectID(result.id)
    delete result.id
  }
  return result
}

const mongoToId = function(entry) {
  const result = { ...entry }
  result.id = result._id
  delete result._id
  return result
}

const mongoToIds = function(entries) {
  return entries.map(entry => mongoToId(entry))
}

module.exports = function buildCollectionMethods({
  getCollection,
  name,
  pluralName,
  validateNew,
}) {
  return {
    [`get ${name} details`]: (query, { reply }) => {
      let mongoQuery
      try {
        mongoQuery = idToMongo(query)
      } catch (err) {
        reply(`${name} not found`, { error: err.message })
        return
      }
      getCollection()
        .find(mongoQuery)
        .toArray((err, entries) => {
          if (err) {
            reply(`${name} not found`, { error: err.message })
            return
          }
          if (entries.length === 0) {
            reply(`${name} not found`)
            return
          }
          reply(`${name} details`, mongoToId(entries[0]))
        })
    },

    [`update ${name}`]: (entryData, { reply }) => {
      let id
      try {
        id = new ObjectID(entryData.id)
      } catch (err) {
        reply(`${name} not found`, { error: err.message })
        return
      }
      delete entryData.id
      getCollection().updateOne(
        { _id: id },
        { $set: entryData },
        (uErr, result) => {
          if (uErr) {
            reply(`${name} not found`, { error: uErr.message })
            return
          }
          if (result.modifiedCount === 0) {
            reply(`${name} not found`)
            return
          }
          getCollection()
            .find({ _id: id })
            .toArray((fErr, entries) => {
              if (fErr) {
                reply(`${name} not found`, { error: fErr.message })
                return
              }
              reply(`${name} updated`, mongoToId(entries[0]))
            })
        }
      )
    },

    [`delete ${name}`]: (query, { reply }) => {
      let id
      try {
        id = new ObjectID(query.id)
      } catch (err) {
        reply(`${name} not found`, { error: err.message })
        return
      }
      getCollection()
        .find({ _id: id })
        .toArray((fErr, entries) => {
          if (fErr) {
            reply(`${name} not found`, { error: fErr.message })
            return
          }
          if (entries.length === 0) {
            reply(`${name} not found`)
            return
          }
          const entry = mongoToId(entries[0])
          getCollection().deleteOne({ _id: id }, (dErr, result) => {
            if (dErr) {
              reply(`${name} not found`, { error: dErr.message })
              return
            }
            if (result.deletedCount === 0) {
              reply(`${name} not found`)
              return
            }
            reply(`${name} deleted`, entry)
          })
        })
    },

    [`create ${name}`]: (entryData, { reply }) => {
      const errorMessage = validateNew(entryData)
      if (errorMessage) {
        reply(`${name} not created`, { error: errorMessage })
        return
      }
      getCollection().insertOne(entryData, (iErr, result) => {
        if (iErr) {
          reply(`${name} not created`, { error: iErr.message })
          return
        }
        reply(`${name} created`, mongoToId(result.ops[0]))
      })
    },

    [`create many ${pluralName}`]: (entries, { reply }) => {
      let vErr
      entries.forEach(entry => {
        if (!vErr) {
          vErr = validateNew(entry)
        }
      })
      if (vErr) {
        reply(`${pluralName} not created`, { error: vErr })
        return
      }
      getCollection().insert(entries, (iErr, result) => {
        if (iErr) {
          reply(`${pluralName} not created`, { error: iErr.message })
          return
        }
        reply(`${pluralName} created`, { count: result.insertedCount })
      })
    },

    [`list ${pluralName}`]: (query, { reply }) => {
      const mongoQuery = {}
      if (query && query.owner_id) {
        mongoQuery.owner_id = query.owner_id.toString()
      }
      getCollection()
        .find(mongoQuery)
        .toArray((fErr, entries) => {
          if (fErr) {
            reply(`${pluralName} not listed`, { error: fErr.message })
            return
          }
          reply(`${pluralName} listed`, {
            count: entries.length,
            entries: mongoToIds(entries),
          })
        })
    },
  }
}
