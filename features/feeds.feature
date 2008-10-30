Feature: Feed Creation
  As a User
  I want to add feeds
  So that I can read things I'm interested it

  Scenario: Creating a new feed
    Given no feeds in the system
    And I am logged in
    And a running collector
    When I create a new feed from http://example.org/feed
    Then I am redirected
