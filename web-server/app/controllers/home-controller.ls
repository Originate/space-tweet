class HomeController

  ({@send}) ->


  index: (req, res) ->
    @send 'list tweets', {}, (data) ->
      res.render 'index', count: data.count, tweets: data.entries


  health-check: (req, res) ->
    res.send-status 200


module.exports = HomeController
