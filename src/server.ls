require! {
  'mongodb' : {MongoClient, ObjectID}
  'nitroglycerin' : N
  'prelude-ls' : {any}
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


  'user.get-details': (query, {reply}) ->
    try
      mongo-query = id-to-mongo query
    catch
      reply 'user.not-found', query
    collection.find(mongo-query).to-array N (users) ->
      switch users.length
        | 0  =>  reply 'user.not-found', query
        | _  =>
            user = users[0]
            mongo-to-id user
            reply 'user.details', user


  'user.update': (user-data, {reply}) ->
    try
      id = new ObjectID user-data.id
    catch
      return reply 'user.not-found', id: user-data.id
    delete user-data.id
    collection.update-one {_id: id}, {$set: user-data}, N (result) ->
      | result.modified-count is 0  =>  return reply 'user.not-found'
      collection.find(_id: id).to-array N (users) ->
        user = users[0]
        mongo-to-id user
        reply 'user.updated', user


  'users.create': (user-data, {reply}) ->
    | empty-name user-data  =>  return reply 'users.not-created', error: 'Name cannot be blank'
    collection.insert-one user-data, (err, result) ->
      | err  =>  return reply 'users.not-created', error: err
      reply 'users.created', mongo-to-id(result.ops[0])


  'users.create-many': (users, {reply}) ->
    | any-empty-names users  =>  return reply 'users.not-created', error: 'Name cannot be blank'
    collection.insert users, (err, result) ->
      | err  =>  return reply 'users.not-created-many', error: err
      reply 'users.created-many', count: result.inserted-count


  'users.list': (_, {reply}) ->
    collection.find({}).to-array N (users) ->
      mongo-to-ids users
      reply 'users.listed', {count: users.length, users}



function any-empty-names users
  any empty-name, users


function empty-name user
  user.name.length is 0


function id-to-mongo query
  result = {[k,v] for k,v of query}
  if result.id
    result._id = new ObjectID result.id
    delete result.id
  result


function mongo-to-id entry
  entry.id = entry._id
  delete entry._id
  entry


function mongo-to-ids entries
  for entry in entries
    mongo-to-id entry
