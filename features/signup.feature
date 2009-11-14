Feature: Signing up with an invitation

In order to use the system
As a user
I want to sign up with my invitation and create my account

  Scenario: Unknown invitation code
    When I use an unknown invitation code
    Then I should see "Your invitation could not be found or has already been used."
    
  Scenario: Signing up only once
    Given an invitation that has already been used
    When I signup with the invitation
    Then I should see "Your invitation could not be found or has already been used."
