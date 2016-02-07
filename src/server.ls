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
      user = result.ops[0]
      user.id = user._id ; delete user._id
      reply 'users.created', user


  'users.create-many': (users, {reply}) ->
    collection.insert users, (err, result) ->
      | err  =>  return reply 'users.not-created-many', error: err
      reply 'users.created-many', count: result.inserted-count


  'users.list': (_, {reply}) ->
    collection.find({}).to-array N (users) ->
      for user in users
        user.id = user._id ; delete user._id
      reply 'users.listed', count: users.length, users: users
