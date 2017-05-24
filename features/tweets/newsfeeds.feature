Feature: Newsfeeds

  When a user goes to the homepage
  They want to see the most recent feeds from people they follow
  So that they get a quick overview of what is going on in SpaceTweet.

  - the newsfeed for a user contains the tweets of people they follow
  - the order of the tweets is determined by the "newsfeed" service


  Scenario: displaying the newsfeed
    Given I am logged in with user id 12345
    And I am following "Jean-Luc Picard" and "William Riker"
    And "Jean-Luc Picard" has been tweeting:
      | CONTENT                                                    | TIME | LIKES   |
      | Resistance is futile!                                      | 12   | 0       |
      | We come in peace!                                          | 14   | 0       |
      | Please ignore my last two tweets, I was hacked by the borg | 20   | 1223233 |
    And "William Riker" has been tweeting:
      | CONTENT                                                       | TIME | LIKES |
      | Just came out of a pretty mechanical meeting with the captain | 13   | 3     |
      | I think the captain is assimilated                            | 16   | 7     |
    When I visit the homepage
    Then the "HTML UI" service emits a "need user newsfeed" message with the payload:
      """
      {
        userId: 12345
      }
      """
    Then my newsfeed shows the tweets:
      | TYPE     | Author          | CONTENT                                                    |
      | featured | Jean-Luc Picard | Please ignore my last two tweets, I was hacked by the borg |
      | normal   | I
