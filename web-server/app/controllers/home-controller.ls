class HomeController

  ({@send}) ->


  index: (req, res) ->
    @send 'list tweets', {}, (message-name, data) ->
      res.render 'index', count: data.count, tweets: data.entries



module.exports = HomeController
