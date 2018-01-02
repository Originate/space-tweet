require! {
  'merge'
}


class UsersController

  ({@send}) ->


  index: (req, res) ->
    @send 'list users', null, (message-name, users) ->
      res.render 'users/index', users


  new: (req, res) ->
    res.render 'users/new'


  create: (req, res) ->
    @send 'create user', req.body, ->
      res.redirect '/users'


  show: (req, res) ->
    @send 'get user details', id: req.params.id, (message-name, user) ->
      res.render 'users/show', {user}


  edit: (req, res) ->
    @send 'get user details', id: req.params.id, (message-name, user) ->
      res.render 'users/edit', {user}


  update: (req, res) ->
    @send 'update user', merge(true, req.params, req.body), ->
      res.redirect '/users'


  destroy: (req, res) ->
    @send 'delete user', req.params, ->
      res.redirect '/users'



module.exports = UsersController
