Feature: Creating multiple users

  As an ExoService application
  I want to be able to create multiple user accounts in one transaction
  So that I don't have to send and receive so many commands and remain performant.

  Rules:
  - send the command "users.create-many" to create several user accounts at once
  - payload is an array of user data
  - when successful, the service replies with "users.created"
    and the newly created account
  - when there is an error, the service replies with "users.not-created"
    and a message describing the error


  Background:
    Given an ExoComm server
    And an instance of this service


  Scenario: creating a valid user account
    When sending the command "users.create" with the payload:
      """
      name: 'Jean-Luc Picard'
      """
    Then the service replies with "users.created" and the payload:
      """
      id: /\d+/
      name: 'Jean-Luc Picard'
      """
    And the service contains the user accounts:
      | NAME            |
      | Jean-Luc Picard |


  Scenario: trying to create a user account with an empty name
    When sending the command "users.create" with the payload:
      """
      name: ''
      """
    Then the service replies with "users.not-created" and the payload:
      """
      error: 'Name cannot be blank'
      """
    And the service contains no users
