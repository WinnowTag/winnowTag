Feature: Logging In
  As a user
  I want to login to winnow
  So that I can view feed item
  
  Scenario: Visiting the feed items page when not logged in
    When I visit /feed_items
    Then I am redirected to the login page
  
  Scenario: Retrieving feed items via ajax when not logged in
    When I visit /feed_items.js
    Then I am redirected via rjs to the login page
