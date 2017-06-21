class TweetsController

  ({@send}) ->


  create: (req, res) ->
    @send 'create tweet', content: req.body.content, owner_id: '1', ->
      res.redirect '/'


  destroy: (req, res) ->
    @send 'delete tweet', req.params, ->
      res.redirect '/'



module.exports = TweetsController

