process.env.NODE_ENV = 'test'

require! {
  'mongodb' : {MongoClient}
  'nitroglycerin' : N
  'cucumber': {After, Before}
}


db = null
get-db = (done) ->
  return done db if db
  MongoClient.connect "mongodb://#{process.env.MONGO_HOST}/space-tweet-tweets-test", N (mongo-db) ->
    db := mongo-db
    done db


Before (_scenario, done) ->
  get-db (db) ->
    db.dropCollection 'tweets', (err) ->
      if err and err.message == 'ns not found'
        done!
      else
        done err

After ->
  @exocom?.close!
  @process?.kill!
