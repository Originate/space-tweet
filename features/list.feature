Feature: Listing all users

  Rules:
  - returns all users currently stored


  Background:
    Given an ExoComm server
    And an instance of this service


  Scenario: no users exist in the database
    When sending the command "users.list"
    Then the service replies with "users.listed" and the payload:
      """
      count: 0
      users: []
      """


  Scenario: users exist in the database
    Given the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | Will Riker      |
    When sending the command "users.list"
    Then the service replies with "users.listed" and the payload:
      """
      count: 2
      users: [
        * name: 'Jean-Luc Picard'
          id: /\d+/
        * name: 'Will Riker'
          id: /\d+/
      ]
      """
