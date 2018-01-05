/* eslint-disable func-names */
process.env.NODE_ENV = 'test'
const { MongoClient } = require('mongodb')
const { After, Before } = require('cucumber')

let dbCache = null
const getDb = async () => {
  if (!dbCache) {
    dbCache = await MongoClient.connect(
      `mongodb://${process.env.MONGO_HOST}/space-tweet-tweets-test`
    )
  }
  return dbCache
}

Before(async () => {
  const db = await getDb()
  const collections = await db.listCollections().toArray()
  await Promise.all(collections.map(c => db.collection(c.name).drop()))
})

After(function() {
  if (this.exocom) {
    this.exocom.close()
  }
  if (this.process) {
    this.process.kill()
  }
})
