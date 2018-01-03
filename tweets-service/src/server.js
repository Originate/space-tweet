const util = require('util')
const { MongoClient, ObjectID } = require('mongodb')
const N = require('nitroglycerin')
const { any } = require('prelude-ls')
const { bootstrap } = require('exoservice')

const emptyContent = function(entry) {
  return entry.content.length === 0
}

const anyEmptyContents = function(entries) {
  return any(emptyContent, entries)
}

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

const mlabsEndpoint = 'ds143608.mlab.com:43608'
const getMongoAddress = function() {
  if (process.env.MONGO_HOST) {
    return `mongodb://${process.env.MONGO_HOST}/space-tweet-tweets-${process.env
      .NODE_ENV || 'dev'}`
  }
  if (!process.env.MONGODB_USER) {
    throw new Error('MONGODB_USER not provided')
  }
  if (!process.env.MONGODB_PW) {
    throw new Error('MONGODB_PW not provided')
  }
  return `mongodb://${process.env.MONGODB_USER}:${
    process.env.MONGODB_PW
  }@${mlabsEndpoint}/space-tweet-tweets-prod`
}

const debug = function(message) {
  console.log(message) // eslint-disable-line no-console
}

let collection = null
bootstrap({
  beforeAll: done => {
    MongoClient.connect(
      getMongoAddress(),
      N(mongoDb => {
        collection = mongoDb.collection('tweets')
        debug(`MongoDB '${mongoDb.databaseName}' connected`)
        done()
      })
    )
  },

  'get tweet details': (query, { reply }) => {
    let mongoQuery
    try {
      mongoQuery = idToMongo(query)
    } catch (error) {
      debug(`the given query (${query}) errored with: ${error}`)
      reply('tweet not found', query)
      return
    }
    collection.find(mongoQuery).toArray(
      N(entries => {
        if (entries.length === 0) {
          debug(`entry '${util.inspect(mongoQuery)}' not found`)
          reply('tweet not found', query)
          return
        }
        const entry = mongoToId(entries[0])
        debug(`reading entry '${entry.content}' (${entry.id})`)
        reply('tweet details', entry)
      })
    )
  },

  'update tweet': (entryData, { reply }) => {
    let id
    try {
      id = new ObjectID(entryData.id)
    } catch (error) {
      debug(`the given query (${entryData}) errored with: ${error}`)
      reply('tweet not found', { id: entryData.id })
      return
    }
    delete entryData.id
    collection.updateOne(
      { _id: id },
      { $set: entryData },
      N(result => {
        if (result.modifiedCount === 0) {
          debug(`entry '${id}' not updated because it doesn't exist`)
          reply('tweet not found')
          return
        }
        collection.find({ _id: id }).toArray(
          N(entries => {
            const entry = mongoToId(entries[0])
            debug(`updating entry '${entry.content}' (${entry.id})`)
            reply('tweet updated', entry)
          })
        )
      })
    )
  },

  'delete tweet': (query, { reply }) => {
    let id
    try {
      id = new ObjectID(query.id)
    } catch (error) {
      debug(`the given query (${query}) errored with: ${error}`)
      reply('tweet not found', { id: query.id })
      return
    }
    collection.find({ _id: id }).toArray(
      N(entries => {
        if (entries.length === 0) {
          debug(`entry '${id}' not deleted because it doesn't exist`)
          reply('tweet not found', query)
          return
        }
        const entry = mongoToId(entries[0])
        collection.deleteOne(
          { _id: id },
          N(result => {
            if (result.deletedCount === 0) {
              debug(`entry '${id}' not deleted because it doesn't exist`)
              reply('tweet not found', query)
              return
            }
            debug(`deleting entry '${entry.content}' (${entry.id})`)
            reply('tweet deleted', entry)
          })
        )
      })
    )
  },

  'create tweet': (entryData, { reply }) => {
    if (emptyContent(entryData)) {
      debug('Cannot create entry: Content cannot be blank')
      reply('tweet not created', { error: 'Content cannot be blank' })
      return
    }
    collection.insertOne(entryData, (err, result) => {
      if (err) {
        debug(`Error creating entry: ${err}`)
        reply('tweet not created', { error: err })
        return
      }
      debug('creating entries')
      reply('tweet created', mongoToId(result.ops[0]))
    })
  },

  'create many tweets': (entries, { reply }) => {
    if (anyEmptyContents(entries)) {
      reply('tweet not created', { error: 'Content cannot be blank' })
      return
    }
    collection.insert(entries, (err, result) => {
      if (err) {
        reply('tweets not created', { error: err })
        return
      }
      reply('tweets created', { count: result.insertedCount })
    })
  },

  'list tweets': (query, { reply }) => {
    const mongoQuery = {}
    if (query && query.owner_id) {
      mongoQuery.owner_id = query.owner_id.toString()
    }
    collection.find(mongoQuery).toArray(
      N(rawEntries => {
        const entries = mongoToIds(rawEntries)
        debug(`listing entries: ${entries.length} found`)
        reply('tweets listed', { count: entries.length, entries })
      })
    )
  },
})
