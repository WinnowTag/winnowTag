Feature: Logging In
  As a user
  I want to login to winnow
  So that I can view feed item
  
  Scenario: Visiting the feed items page when not logged in
		Given There is a demo user
    When I am on the feed items page
    Then I am redirected to the default page
  
  Scenario: Retrieving feed items via ajax when not logged in
    When I visit /feed_items.js
    Then I am redirected via rjs to the default page

  Scenario: Accessing feed items page when logged in
		Given I am logged in
		When I am on the feed items page
		Then I should be on the feed items page
		
	Scenario: Logging in should take you to the main app
		When I log in
		Then I should be on the feed items page

  Scenario: Logging in with a wrong pass should take me to the login page
		When I log in with the wrong password
		Then I should be on the login page

	Scenario: Logging out should take you to the demo page
		Given There is a demo user
		Given I am logged in
		When I go to logout
		Then I should be on the default page

  Scenario: Accessing the default page when logged in should take you to the main app
		Given There is a demo user
		Given I am logged in
		When I am on the default page
		Then I am redirected to the feed items page
