Feature: Logging In

  When using the application
  I want to log in
  So that I can use the configuration associated with my account.

  Rules:
  - only active users can log in
  - login requires a correct password
  - when the user has been away for less than 7 days, she is greeted with "Hi <name>"
  - when the user has been away for more than 7 days, she is greeted with "Welcome back, <name>"


  Background:
    Given an existing user account:
      | NAME            | EMAIL                | PASSWORD   |
      | Jean-Luc Picard | picard@starfleet.gov | enterprise |


  Scenario: an existing user logs in after 8 days
    Given today is May 20
    When a user goes to "/login" and enters:
      | EMAIL                | PASSWORD   |
      | picard@starfleet.gov | enterprise |
    Then the "HTML" service emits a "login attempt" message with the payload:
      """
      {
        email: "picard@starfleet.com",
        passwordSha1: "1th3nt234324nt23"
      }
      """
    And the "password credentials" service replies with a "correct password" message"
    And the "account status" service replies with an "active account" message
    And the "last login" service replies with a "last login date" message and the payload:
      """
      {
        date: "2017-05-12",
        daysAgo: 8
      }
      """
    And the "HTML" service emits a "session created" message with the payload:
      """
      {
        sessionId: "23423423423423",
        sessionPayload: {
          userId: "34234234",
          userName: "Jean-Luc Picard"
        }
      }
      """
    And the "HTML" service emits a "user logged in" message
    And the web UI displays "Welcome back, Jean-Luc!"
    And the web client has a session cookie set with the content:
      """
      23423423423423
      """


  Scenario: trying to log into a non-existing account
    When a user goes to "/login" and enters:
      | EMAIL                | PASSWORD |
      | nobody@starfleet.gov | foo      |
    Then the "HTML" service emits a "login attempt" message with the payload:
      """
      {
        email: "foo@starfleet.com",
        password_sha1: "1th3nt234324nt23"
      }
      """
    And the "password credentials" service replies with a "incorrect password" message"
    And the web UI displays "incorrect username or password. Please try again"


  Scenario: trying to log into a disabled account
    Given the account "kirk@starfleet.com" is disabled
    When a user goes to "/login" and enters:
      | EMAIL              | PASSWORD   |
      | kirk@starfleet.gov | enterprise |
    Then the "HTML" service emits a "login attempt" message with the payload:
      """
      {
        email: "kirk@starfleet.com",
        password_sha1: "1th3nt234324nt23"
      }
      """
    And the "password credentials" service replies with a "correct password" message"
    And the "account status" service replies with an "inactive account" message"
    And the web UI displays "inactive account"


  Scenario: trying to log in with the wrong password
    Given an existing user account:
      | NAME            | EMAIL                | PASSWORD   |
      | Jean-Luc Picard | picard@starfleet.gov | enterprise |
    When a user goes to "/login" and enters:
      | EMAIL                | PASSWORD |
      | picard@starfleet.gov | zonk     |
    Then the "HTML" service emits a "login attempt" message with the payload:
      """
      {
        email: "picard@starfleet.com",
        password_sha1: "1th3nt234324nt23"
      }
      """
    And the "password credentials" service replies with an "incorrect password" message"
    And the "account status" service replies with an "active account" message"
    And the web UI displays "wrong username or password. Please try again"
