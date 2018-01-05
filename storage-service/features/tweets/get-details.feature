Feature: Get details for an entry

  Rules:
  - when receiving "get tweet details", returns "tweet details" with details for the given entry


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the tweets:
      | CONTENT   |
      | Monday    |
      | Tuesday   |
      | Wednesday |


  Scenario: locating an existing entry by id
    When sending the message "get tweet details" with the payload:
      """
      {"id": "<%= @id_of 'Tuesday' %>"}
      """
    Then the service replies with "tweet details" and the payload:
      """
      {
        "id": "<generated>",
        "content": "Tuesday"
      }
      """


  Scenario: locating an existing entry by content
    When sending the message "get tweet details" with the payload:
      """
      {"content": "Tuesday"}
      """
    Then the service replies with "tweet details" and the payload:
      """
      {
        "id": "<generated>",
        "content": "Tuesday"
      }
      """


  Scenario: locating a non-existing entry by id
    When sending the message "get tweet details" with the payload:
      """
      {"id": "zonk"}
      """
    Then the service replies with "tweet not found"


  Scenario: locating a non-existing entry by content
    When sending the message "get tweet details" with the payload:
      """
      {"content": "zonk"}
      """
    Then the service replies with "tweet not found"
