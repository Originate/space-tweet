Feature: creating tweets

  When coming across a noteworthy insight
  I want to be able to create a new tweent
  So that I can share it with the world


  @web
  Scenario: creating a tweet via the web UI
    Given I am logged in as "Jean-Luc Picard"
    When clicking on the "create tweet" icon
    And entering:
      """
      How do you call an indecisive bee? A maybe!
      """
    And clicking on the "post" button
    Then the HTML service emits a "user submitted tweet" message with the payload:
      """
      {
        content: "How do you call an indecivise bee? A maybe!"
      }
      """
    And the "tweets" service replies with a "tweet created" message and the payload:
      """
      {
        creatorId: 32342,
        content: "How do you call an indecivise bee? A maybe!"
      }
      """
    And the web UI displays "tweet created"








