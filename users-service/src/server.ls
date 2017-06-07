require! {
  'mongodb' : {MongoClient, ObjectID}
  'nitroglycerin' : N
  'prelude-ls' : {any}
  'require-yaml'
  'util'
}
env = require('get-env')('test')


collection = null

module.exports =

  before-all: (done) ->
    MongoClient.connect get-mongo-address!, N (mongo-db) ->
      collection := mongo-db.collection 'users'
      console.log "MongoDB #{mongo-db.database-name} connected"
      done!


  'user.get-details': (query, {reply}) ->
    try
      mongo-query = id-to-mongo query
    catch
      console.log "the given query (#{query}) contains an invalid id"
      return reply error: 'invalid-id'
    collection.find(mongo-query).to-array N (users) ->
      switch users.length
        | 0  =>
            console.log "user '#{mongo-query}' not found"
            reply error: 'not-found'
        | _  =>
            user = users[0]
            mongo-to-id user
            console.log "reading user '#{user.name}' (#{user.id})"
            reply {user}


  'user.update': (user-data, {reply}) ->
    try
      id = new ObjectID user-data.id
    catch
      console.log "the given query (#{user-data}) contains an invalid id"
      return reply error: 'invalid-id'
    delete user-data.id
    collection.update-one {_id: id}, {$set: user-data}, N (result) ->
      switch result.modified-count
        | 0  =>
            console.log "user '#{id}' not updated because it doesn't exist"
            return reply error: 'not-found'
        | _  =>
            collection.find(_id: id).to-array N (users) ->
              user = users[0]
              mongo-to-id user
              console.log "updating user '#{user.name}' (#{user.id})"
              reply {user}


  'user.delete': (query, {reply}) ->
    try
      id = new ObjectID query.id
    catch
      console.log "the given query (#{query}) contains an invalid id"
      return reply error: 'invalid-id'
    collection.find(_id: id).to-array N (users) ->
      | users.length is 0  =>
          console.log "user '#{id}' not deleted because it doesn't exist"
          return reply error: 'not-found'
      user = users[0]
      mongo-to-id user
      collection.delete-one _id: id, N (result) ->
        if result.deleted-count is 0
          console.log "user '#{id}' not deleted because it doesn't exist"
          return reply error: 'not-found'
        console.log "deleting user '#{user.name}' (#{user.id})"
        reply {user}


  'users.create': (user-data, {reply}) ->
    | empty-name user-data  =>
        console.log 'Cannot create user: Name cannot be blank'
        return reply error: 'Name cannot be blank'
    collection.insert-one user-data, (err, result) ->
      if err
        console.log "Error creating user: #{err}"
        return reply error: err
      console.log "creating user '#{user-data.name}'"
      reply id: mongo-to-id(result.ops[0])


  'users.create-many': (users, {reply}) ->
    | any-empty-names users  =>  return error: 'Name cannot be blank'
    collection.insert users, (err, result) ->
      | err  =>  return reply error: err
      reply count: result.inserted-count


  'users.list': (_, {reply}) ->
    collection.find({}).to-array N (users) ->
      mongo-to-ids users
      console.log "listing users: #{users.length} found"
      reply {count: users.length, users}



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


function get-mongo-config
  require('../service.yml').dependencies.mongo


function get-mongo-address
  mongo-config = get-mongo-config!
  return "mongodb://#{process.env.MONGO}/space-tweet-users-dev" if process.env.MONGO
  switch env
    | \test => "mongodb://localhost:27017/space-tweet-users-test"
    | \prod =>
      process.env.MONGODB_USER ? throw new Error "MONGODB_USER not provided"
      process.env.MONGODB_PW ? throw new Error "MONGODB_PW not provided"
      "mongodb://#{process.env.MONGODB_USER}:#{process.env.MONGODB_PW}@#{mongo-config.prod}/space-tweet-users-prod"
