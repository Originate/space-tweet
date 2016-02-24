require! {
  'mongodb' : {MongoClient}
  'nitroglycerin' : N
}
debug = require('debug')('users-service')
env = require('get-env')('test')


collection = null

module.exports =

  before-all: (done) ->
    MongoClient.connect "mongodb://localhost:27017/space-tweet-users-#{env}", N (mongo-db) ->
      collection := mongo-db.collection 'users'
      debug 'MongoDB connected'
      done!


  'users.create': (user-data, {reply}) ->
    | not user-data.name  =>  return reply 'users.not-created', error: 'Name cannot be blank'
    collection.insert-one user-data, (err, result) ->
      | err  =>  return reply 'users.not-created', error: err
      reply 'users.created', mongo-to-id(result.ops[0])


  'users.create-many': (users, {reply}) ->
    collection.insert users, (err, result) ->
      | err  =>  return reply 'users.not-created-many', error: err
      reply 'users.created-many', count: result.inserted-count


  'users.list': (_, {reply}) ->
    collection.find({}).to-array N (users) ->
      mongo-to-ids users
      reply 'users.listed', count: users.length, users: users



function mongo-to-id entry
  entry.id = entry._id ; delete entry._id
  entry


function mongo-to-ids entries
  for entry in entries
    mongo-to-id entry
