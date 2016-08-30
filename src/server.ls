require! {
  'mongodb' : {MongoClient, ObjectID}
  'nitroglycerin' : N
  'prelude-ls' : {any}
  'util'
}
env = require('get-env')('test')


collection = null

module.exports =

  before-all: (done) ->
    mongo-db-name = "exosphere-mongo-service-#{env}"
    MongoClient.connect "mongodb://localhost:27017/#{mongo-db-name}", N (mongo-db) ->
      collection := mongo-db.collection 'tweets'
      console.log "MongoDB '#{mongo-db-name}' connected"
      done!


  'tweets.get-details': (query, {reply}) ->
    try
      mongo-query = id-to-mongo query
    catch
      console.log "the given query (#{query}) contains an invalid id"
      return reply 'tweets.not-found', query
    collection.find(mongo-query).to-array N (entries) ->
      if entries.length is 0
        console.log "entry '#{util.inspect mongo-query}' not found"
        return reply 'tweets.not-found', query
      entry = entries[0]
      mongo-to-id entry
      console.log "reading entry '#{entry.content}' (#{entry.id})"
      reply 'tweets.details', entry


  'tweets.update': (entry-data, {reply}) ->
    try
      id = new ObjectID entry-data.id
    catch
      console.log "the given query (#{entry-data}) contains an invalid id"
      return reply 'tweets.not-found', id: entry-data.id
    delete entry-data.id
    collection.update-one {_id: id}, {$set: entry-data}, N (result) ->
      switch result.modified-count
        | 0  =>
            console.log "entry '#{id}' not updated because it doesn't exist"
            return reply 'tweets.not-found'
        | _  =>
            collection.find(_id: id).to-array N (entries) ->
              entry = entries[0]
              mongo-to-id entry
              console.log "updating entry '#{entry.content}' (#{entry.id})"
              reply 'tweets.updated', entry


  'tweets.delete': (query, {reply}) ->
    try
      id = new ObjectID query.id
    catch
      console.log "the given query (#{util.inspect query}) contains an invalid id"
      return reply 'tweets.not-found', id: query.id
    collection.find(_id: id).to-array N (entries) ->
      if entries.length is 0
        console.log "entry '#{id}' not deleted because it doesn't exist"
        return reply 'tweets.not-found', query
      entry = entries[0]
      mongo-to-id entry
      collection.delete-one _id: id, N (result) ->
        if result.deleted-count is 0
          console.log "entry '#{id}' not deleted because it doesn't exist"
          return reply 'tweets.not-found', query
        console.log "deleting entry '#{entry.content}' (#{entry.id})"
        reply 'tweets.deleted', entry


  'tweets.create': (entry-data, {reply}) ->
    | empty-content entry-data  =>
        console.log 'Cannot create entry: Content cannot be blank'
        return reply 'tweets.not-created', error: 'Content cannot be blank'
    collection.insert-one entry-data, (err, result) ->
      if err
        console.log "Error creating entry: #{err}"
        return reply 'tweets.not-created', error: err
      console.log "creating entries"
      reply 'tweets.created', mongo-to-id(result.ops[0])


  'tweets.create-many': (entries, {reply}) ->
    | any-empty-contents entries  =>  return reply 'tweets.not-created', error: 'Content cannot be blank'
    collection.insert entries, (err, result) ->
      | err  =>  return reply 'tweets.not-created-many', error: err
      reply 'tweets.created-many', count: result.inserted-count


  'tweets.list': (query, {reply}) ->
    mongo-query = if query?.owner_id
      {"owner_id": query.owner_id.to-string!}
    else
      {}
    collection.find(mongo-query).to-array N (entries) ->
      mongo-to-ids entries
      console.log "listing entries: #{entries.length} found"
      reply 'tweets.listed', {count: entries.length, entries}



function any-empty-contents entries
  any empty-content, entries


function empty-content entry
  entry.content.length is 0


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
