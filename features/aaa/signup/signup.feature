Feature: Signing Up

  When a user starts using SpaceTweet
  They want to create an account
  So that they can start subscribing to other users.


  Scenario: a user signs up via the web
    Given the user goes to "spacetweet.com/signup" and enters:
      | NAME       | John Doe          |
      | EMAIL      | john.doe@test.com |
      | ACCEPT TOS | yes               |
    When the user clicks on the "Sign up" button
    Then the "HTML service" emaits a "user signed up" message
    And the "user service" emits a "user account created" message
    And the web UI shows "Sign up successful"
    And the application now contains the user accounts:
      | NAME     | EMAIL              | STATUS |
      | John Doe | john.doe@gmail.com | active |
    And the "welcome email service" sends a welcome email to "john.doe@test.com"


  Scenario: a user tries to sign up with an exiting email address
    Given an existing user account with the email "john.doe@test.com"
    And the user goes to "spacetweet.com/signup" and enters:
      | NAME       | John Doe          |
      | EMAIL      | john.doe@test.com |
      | ACCEPT TOS | yes               |
    When the user clicks on the "Sign up" button
    Then the HTML service emits a "user signed up" message
    And the user-service emits a "user account already exists" message
    And the web UI shows:
      """
      An account 'john.doe@test.com' already exists.
      Please log in
      """
    And the application still contains the user accounts:
      | NAME     | EMAIL              | STATUS |
      | John Doe | john.doe@gmail.com | active |
