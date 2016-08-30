Feature: Listing all entries

  As a developer working on an application that uses lots of entries
  I want to have an easy way to get a list of all entries
  So that I can display overview pages.

  Rules:
  - returns all entries currently stored


  Background:
    Given an ExoCom server
    And an instance of this service


  Scenario: no entries exist in the database
    When sending the message "tweets.list" with the payload:
      """
      owner_id: 1
      """
    Then the service replies with "tweets.listed" and the payload:
      """
      count: 0
      entries: []
      """


  Scenario: listing entries of a user
    Given the service contains the entries:
      | OWNER_ID | CONTENT                 |
      | 1        | Hello world!            |
      | 1        | Hello again!            |
      | 2        | Entry from another user |
    When sending the message "tweets.list" with the payload:
      """
      owner_id: 1
      """
    Then the service replies with "tweets.listed" and the payload:
      """
      count: 2
      entries: [
        * content: 'Hello world!'
          id: /\d+/
          owner_id: "1"
        * content: 'Hello again!'
          id: /\d+/
          owner_id: "1"
      ]
      """


  Scenario: listing entries of all users
    Given the service contains the entries:
      | OWNER_ID | CONTENT                 |
      | 1        | Hello world!            |
      | 1        | Hello again!            |
      | 2        | Entry from another user |
    When sending the message "tweets.list"
    Then the service replies with "tweets.listed" and the payload:
      """
      count: 3
      entries: [
        * content: 'Hello world!'
          id: /\d+/
          owner_id: '1'
        * content: 'Hello again!'
          id: /\d+/
          owner_id: '1'
        * content: 'Entry from another user'
          id: /\d+/
          owner_id: '2'
      ]
      """
