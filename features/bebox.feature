Feature: My bootstrapped app kinda works
  In order to get going on coding my awesome app
  I want to have aruba and cucumber setup
  So I don't have to do it myself

  Scenario: App just runs
    When I get help for "bebox"
    Then the exit status should be 0

  Scenario: Create Valid Project
    When I want to create a new project called "bebox"
    Then the exit status should be 0
