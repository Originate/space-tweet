Feature: Creating multiple users

  As an ExoService application
  I want to be able to create multiple user accounts in one transaction
  So that I don't have to send and receive so many messages and remain performant.

  Rules:
  - send the message "users.create-many" to create several user accounts at once
  - payload is an array of user data
  - when successful, the service replies with "users.created"
    and the newly created account
  - when there is an error, the service replies with "users.not-created"
    and a message describing the error


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: creating valid user accounts
    When sending the message "users.create-many" with the payload:
      """
      [
        * name: 'Jean-Luc Picard'
        * name: 'William Riker'
      ]
      """
    Then the service replies with "users.created-many" and the payload:
      """
      count: 2
      """
    And the service now contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |


  Scenario: trying to create a user account with an empty name
    When sending the message "users.create-many" with the payload:
      """
      [
        * name: 'Jean-Luc Picard'
        * name: ''
      ]
      """
    Then the service replies with "users.not-created" and the payload:
      """
      error: 'Name cannot be blank'
      """
    And the service contains no users
