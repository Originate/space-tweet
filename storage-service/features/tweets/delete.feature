Feature: Deleting an entry

  Rules:
  - when receiving "delete tweet", removes the entry with the given id and returns "tweet deleted"


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the tweets:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Tuesday   | 1        |
      | Wednesday | 1        |


  Scenario: deleting an existing entry
    When sending the message "delete tweet" with the payload:
      """
      {"id": "<%= @id_of 'Tuesday' %>"}
      """
    Then the service replies with "tweet deleted" and the payload:
      """
      {
        "id": "<generated>",
        "owner_id": "1",
        "content": "Tuesday"
      }
      """
    And the service now contains the tweets:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Wednesday | 1        |


  Scenario: trying to delete a non-existing entry
    When sending the message "delete tweet" with the payload:
      """
      {"id": "zonk"}
      """
    Then the service replies with "tweet not found"
    And the service now contains the tweets:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Tuesday   | 1        |
      | Wednesday | 1        |
