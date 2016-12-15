Feature: Get details for an entry

  Rules:
  - when receiving "tweets.get-details", returns "tweets.details" with details for the given entry


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the entries:
      | CONTENT   |
      | Monday    |
      | Tuesday   |
      | Wednesday |


  Scenario: locating an existing entry by id
    When sending the message "tweets.get-details" with the payload:
      """
      id: '<%= @id_of 'Tuesday' %>'
      """
    Then the service replies with "tweets.details" and the payload:
      """
      id: /.+/
      content: 'Tuesday'
      """


  Scenario: locating an existing entry by content
    When sending the message "tweets.get-details" with the payload:
      """
      content: 'Tuesday'
      """
    Then the service replies with "tweets.details" and the payload:
      """
      id: /.+/
      content: 'Tuesday'
      """


  Scenario: locating a non-existing entry by id
    When sending the message "tweets.get-details" with the payload:
      """
      id: 'zonk'
      """
    Then the service replies with "tweets.not-found" and the payload:
      """
      id: 'zonk'
      """


  Scenario: locating a non-existing entry by content
    When sending the message "tweets.get-details" with the payload:
      """
      content: 'zonk'
      """
    Then the service replies with "tweets.not-found" and the payload:
      """
      content: 'zonk'
      """
