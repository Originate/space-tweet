require! {
  'merge'
}


class UsersController

  ({@send}) ->


  index: (req, res) ->
    @send 'list users', null, (users) ->
      res.render 'users/index', users


  new: (req, res) ->
    res.render 'users/new'


  create: (req, res) ->
    @send 'create users', req.body, ->
      res.redirect '/users'


  show: (req, res) ->
    @send 'get users details', id: req.params.id, (user) ->
      res.render 'users/show', {user}


  edit: (req, res) ->
    @send 'get users details', id: req.params.id, (user) ->
      res.render 'users/edit', {user}


  update: (req, res) ->
    @send 'update users', merge(true, req.params, req.body), ->
      res.redirect '/users'


  destroy: (req, res) ->
    @send 'delete users', req.params, ->
      res.redirect '/users'



module.exports = UsersController
