Feature: Disable the user account after unsuccessful login features

  When somebody is trying to guess my password
  I want my account to be temporarily suspended
  So that the attacker doesn't get enough tries.

  - after 5 wrong passwords, the account cannot log in for another hours


  Scenario: 5 wrong login attempts
    Given the user account:
      | ID    | EMAIL         |
      | 12345 | user@test.com |
    When an "incorrect password" message is sent 5 times for this account
    Then the "password abuse" service emits a "block account" message with the payload:
      """
      {
        accountId: 12323423,
        duration: 10,
        reason: "5 incorrect password attempts"
      }
      """
    And the "password abuse" service emits a "set timer" message
    And the "timer" service replies with a "timer set" message and the payload:
      """
      {
        timerId: 3434343,
        time left: 600
      }
      """


  Scenario: trying to log into a blocked account
    Given a user account with the id 12345
    And the message "block account" with the payload:
      """
      {
        accountId: 12345,
        duration: 10,
        reason: "testing"
      }
      """
    When the "HTML UI" service emits a "login attempt" message with the payload:
      """
      {
        accountId: 12345,
        passwordSha: "oneuthonutoh"
      }
      """
    Then the "account status" service replies with an "blocked account" message and the payload:
      """
      {
        reason: "testing"
      }
      """
    And the web UI displays:
      """
      account is blocked. Reason: "testing"
      """

  Scenario: releasing the blocked account after the timeout
    Given an account with id 12345
    And the message "block account" with the payload:
      """
      {
        accountId: 12345,
        duration: 10,
        reason: "testing"
      }
      """
    And the "password abuse" service emits a "set timer" message
    When the "timer" service replies with "timer expired" message
    Then it is possible to log into this account again
