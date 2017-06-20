Feature: Deleting a user

  Rules:
  - when receiving "delete users", removes the user with the given id and returns "user deleted"


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |


  Scenario: deleting an existing user
    When sending the message "delete users" with the payload:
      """
      id: '<%= @id_of 'Jean-Luc Picard' %>'
      """
    Then the service replies with "user deleted" and the payload:
      """
      id: /.+/
      name: 'Jean-Luc Picard'
      """
    And the service now contains the users:
      | NAME          |
      | William Riker |


  Scenario: trying to delete a non-existing user
    When sending the message "delete users" with the payload:
      """
      id: 'zonk'
      """
    Then the service replies with "user not found" and the payload:
      """
      id: 'zonk'
      """
    And the service now contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |
