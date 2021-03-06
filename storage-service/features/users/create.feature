Feature: Creating users

  Rules:
  - users must have a name
  - when successful, the service replies with "user created"
    and the newly created account
  - when there is an error, the service replies with "user not created"
    and a message describing the error


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: creating a valid user account
    When sending the message "create user" with the payload:
      """
      {"name": "Jean-Luc Picard"}
      """
    Then the service replies with "user created" and the payload:
      """
      {
        "id": "<generated>",
        "name": "Jean-Luc Picard"
      }
      """
    And the service now contains the users:
      | NAME            |
      | Jean-Luc Picard |


  Scenario: trying to create a user account with an empty name
    When sending the message "create user" with the payload:
      """
      {"name": ""}
      """
    Then the service replies with "user not created"
    And the service contains no users
