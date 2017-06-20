Feature: Updating a user

  Rules:
  - when receiving "user.update", updates the user with the given id and returns "user updated" with the new record


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |


  Scenario: updating an existing user
    When sending the message "user.update" with the payload:
      """
      id: '<%= @id_of 'Jean-Luc Picard' %>'
      name: 'Cptn. Picard'
      """
    Then the service replies with "user updated" and the payload:
      """
      id: /.+/
      name: 'Cptn. Picard'
      """
    And the service now contains the users:
      | NAME          |
      | Cptn. Picard  |
      | William Riker |


  Scenario: trying to update a non-existing user
    When sending the message "user.update" with the payload:
      """
      id: 'zonk'
      name: 'Cptn. Zonk'
      """
    Then the service replies with "user not found" and the payload:
      """
      id: 'zonk'
      """
    And the service now contains the users:
      | NAME            |
      | Jean-Luc Picard |
      | William Riker   |
