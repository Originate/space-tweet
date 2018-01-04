/* eslint-disable func-names */
process.env.NODE_ENV = 'test'
const { MongoClient } = require('mongodb')
const N = require('nitroglycerin')
const { After, Before } = require('cucumber')

let dbCache = null
const getDb = done => {
  if (dbCache) {
    done(dbCache)
    return
  }
  MongoClient.connect(
    `mongodb://${process.env.MONGO_HOST}/space-tweet-tweets-test`,
    N(mongoDb => {
      dbCache = mongoDb
      done(dbCache)
    })
  )
}

Before((_scenario, done) => {
  getDb(db => {
    db.dropCollection('tweets', err => {
      if (err && err.message === 'ns not found') {
        done()
      } else {
        done(err)
      }
    })
  })
})

After(function() {
  if (this.exocom) {
    this.exocom.close()
  }
  if (this.process) {
    this.process.kill()
  }
})
