Feature: Updating an entry

  Rules:
  - when receiving "tweets.update", updates the entry with the given id and returns "tweets.updated" with the new record


  Background:
    Given an ExoCom server
    And an instance of this service
    And the service contains the entries:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Tuesday   | 1        |
      | Wednesday | 1        |


  Scenario: updating an existing entry
    When sending the message "tweets.update" with the payload:
      """
      id: '<%= @id_of 'Tuesday' %>'
      content: 'Dienstag'
      """
    Then the service replies with "tweets.updated" and the payload:
      """
      id: /.+/
      content: 'Dienstag'
      owner_id: '1'
      """
    And the service now contains the entries:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Dienstag  | 1        |
      | Wednesday | 1        |


  Scenario: trying to update a non-existing entry
    When sending the message "tweets.update" with the payload:
      """
      id: 'zonk'
      content: 'feel the zonk'
      """
    Then the service replies with "tweets.not-found" and the payload:
      """
      id: 'zonk'
      """
    And the service now contains the entries:
      | CONTENT   | OWNER_ID |
      | Monday    | 1        |
      | Tuesday   | 1        |
      | Wednesday | 1        |
