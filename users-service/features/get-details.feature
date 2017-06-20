Feature: Get details for a user

  Rules:
  - when receiving "user details", returns "user details" with details for the given user


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |


  Scenario: locating an existing user by id
    When sending the message "user.get-details" with the payload:
      """
      id: '<%= @id_of 'Jean-Luc Picard' %>'
      """
    Then the service replies with "user details" and the payload:
      """
      id: /.+/
      name: 'Jean-Luc Picard'
      """


  Scenario: locating an existing user by name
    When sending the message "user.get-details" with the payload:
      """
      name: 'Jean-Luc Picard'
      """
    Then the service replies with "user details" and the payload:
      """
      id: /.+/
      name: 'Jean-Luc Picard'
      """


  Scenario: locating a non-existing user by id
    When sending the message "user.get-details" with the payload:
      """
      id: 'zonk'
      """
    Then the service replies with "user not found" and the payload:
      """
      id: 'zonk'
      """


  Scenario: locating a non-existing user by name
    When sending the message "user.get-details" with the payload:
      """
      name: 'zonk'
      """
    Then the service replies with "user not found" and the payload:
      """
      name: 'zonk'
      """
