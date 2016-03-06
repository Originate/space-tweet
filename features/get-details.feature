Feature: Get details for a user

  Rules:
  - when receiving "user.details", returns "user.details" with details for the given user


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |


  Scenario: requesting details for an existing user
    When sending the message "user.get-details" with the payload:
      """
      name: 'Jean-Luc Picard'
      """
    Then the service replies with "user.details" and the payload:
      """
      id: /.+/
      name: 'Jean-Luc Picard'
      """
