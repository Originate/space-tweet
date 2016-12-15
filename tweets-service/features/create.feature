Feature: Creating entries

  Rules:
  - entries must have a content
  - when successful, the service replies with "tweets.created"
    and the newly created entry
  - when there is an error, the service replies with "tweets.not-created"
    and a message describing the error


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: creating a valid entry
    When sending the message "tweets.create" with the payload:
      """
      owner_id: '1'
      content: 'Hello world'
      """
    Then the service replies with "tweets.created" and the payload:
      """
      id: /\d+/
      owner_id: '1'
      content: 'Hello world'
      """
    And the service now contains the entries:
      | CONTENT     | OWNER_ID |
      | Hello world | 1        |


  Scenario: trying to create an entry with empty content
    When sending the message "tweets.create" with the payload:
      """
      owner_id: '1'
      content: ''
      """
    Then the service replies with "tweets.not-created" and the payload:
      """
      error: 'Content cannot be blank'
      """
    And the service contains no entries
