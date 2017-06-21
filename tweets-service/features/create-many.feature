Feature: Creating multiple entries

  As an ExoService application
  I want to be able to create multiple entries in one transaction
  So that I don't have to send and receive so many messages and remain performant.

  Rules:
  - send the message "create tweet-many" to create several entries at once
  - payload is an array of entry data
  - when successful, the service replies with "tweet created"
    and the newly created account
  - when there is an error, the service replies with "tweet not created"
    and a message describing the error


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: creating valid entries
    When sending the message "create tweet-many" with the payload:
      """
      [
        * content: 'Monday'
        * content: 'Tuesday'
      ]
      """
    Then the service replies with "tweet created-many" and the payload:
      """
      count: 2
      """
    And the service contains the entries:
      | CONTENT |
      | Monday  |
      | Tuesday |


  Scenario: trying to create entries with empty content
    When sending the message "create tweet-many" with the payload:
      """
      [
        * content: 'Monday'
        * content: ''
      ]
      """
    Then the service replies with "tweet not created" and the payload:
      """
      error: 'Content cannot be blank'
      """
    And the service contains no entries
