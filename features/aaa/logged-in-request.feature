Feature: logged in request

  - the browser session contains the session id
  - when a request comes in, the "HTML UI" service emits a "user


  Scenario: a logged in user makes a request
    Given I am logged in as user "Jean-Luc Picard" with id 12345
    When I browse the homepage
    Then the "HTML UI" service emits a "raw session request" message with the payload:
      """
      {
        sessionId: "34234234234"
      }
      """
    And the "session" service replies with a "decoded session" message and the payload:
      """
      {
        sessionId: "34234234234",
        sessionPayload: {
          userId: 12345,
          userName: "Jean-Luc Picard"
        }
      }
      """
