class TweetsController

  ({@send}) ->


  create: (req, res) ->
    @send 'create tweets', content: req.body.content, owner_id: '1', ->
      res.redirect '/'


  destroy: (req, res) ->
    @send 'delete tweets', req.params, ->
      res.redirect '/'



module.exports = TweetsController

