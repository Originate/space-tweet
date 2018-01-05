Feature: Listing all users

  Rules:
  - returns all users currently stored


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: no users exist in the database
    When sending the message "list users"
    Then the service replies with "users listed" and the payload:
      """
      {
        "count": 0,
        "entries": []
      }
      """


  Scenario: users exist in the database
    Given the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | Will Riker      |
    When sending the message "list users"
    Then the service replies with "users listed" and the payload:
      """
      {
        "count": 2,
        "entries": [
          {
            "id": "<generated>",
            "name": "Jean-Luc Picard"
          }, {
            "id": "<generated>",
            "name": "Will Riker"
          }
        ]
      }
      """
