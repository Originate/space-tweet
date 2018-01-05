const { MongoClient } = require('mongodb')
const { bootstrap } = require('exoservice')
const buildCollectionMethods = require('./build_collection_methods')

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

let collection = null

const methods = buildCollectionMethods({
  getCollection: () => collection,
  name: 'tweet',
  pluralName: 'tweets',
  validateNew: entry => {
    if (entry.content.length === 0) {
      return 'Content cannot be blank'
    }
    return null
  },
})

methods.beforeAll = done => {
  MongoClient.connect(getMongoAddress(), (err, mongoDb) => {
    if (err) {
      throw new Error('Unable to connect to MongoDB')
    }
    collection = mongoDb.collection('tweets')
    console.log(`MongoDB '${mongoDb.databaseName}' connected`) // eslint-disable-line no-console
    done()
  })
}

bootstrap(methods)
