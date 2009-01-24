Feature: Feed Creation
  As a User
  I want to add feeds
  So that I can read things I'm interested it

  Scenario: Creating a new feed
    Given I am logged in
      And there is not a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then I am redirected to the feeds page
      And I see the notice "Thanks for adding the feed from http://www.example.com/feed.atom. We will fetch the items soon. The feed has also been added to your feeds folder in the sidebar."
      And I see the feed for "http://www.example.com/feed.atom"

  Scenario: Creating a new feed subscribes the current user to the new feed
    Given I am logged in
      And there is not a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then I am subscribed to "http://www.example.com/feed.atom"

  Scenario: Creating a new feed creates the same feed on the collector
    Given I am logged in
      And there is not a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then "http://www.example.com/feed.atom" is created on the collector

  Scenario: Creating a new feed schedules it for collection
    Given I am logged in
      And there is not a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then  "http://www.example.com/feed.atom" is scheduled for collection

  Scenario: Creating an existing feed
    Given I am logged in
      And there is a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then I am redirected to the feeds page
      And I see the notice "We already have the feed from http://www.example.com/feed.atom, however we will update it now. The feed has also been added to your feeds folder in the sidebar."
      And I see the feed for "http://www.example.com/feed.atom"

  Scenario: Creating an existing feed subscribes the current user to the new feed
    Given I am logged in
      And there is a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then I am subscribed to "http://www.example.com/feed.atom"

  Scenario: Creating an existing feed creates the same feed on the collector
    Given I am logged in
      And there is a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then "http://www.example.com/feed.atom" is created on the collector

  Scenario: Creating an existing feed schedules it for collection
    Given I am logged in
      And there is a feed for "http://www.example.com/feed.atom"
    When I create a feed for "http://www.example.com/feed.atom"
    Then  "http://www.example.com/feed.atom" is scheduled for collection

  Scenario: Creating a new feed without a url
    Given I am logged in
    When I create a feed for ""
    Then I see the add feeds form
      And I see the url is set to ""
      And I see the error "Url is not http"

  Scenario: Creating a new feed from a non-http url
    Given I am logged in
    When I create a feed for "ftp://www.example.com/feed.atom"
    Then I see the add feeds form
      And I see the url is set to "ftp://www.example.com/feed.atom"
      And I see the error "Url is not http"

  Scenario: Creating a new feed with an invalid url
    Given I am logged in
    When I create a feed for "http://invalid_subdomain.example.com/feed.atom"
    Then I see the add feeds form
      And I see the url is set to "http://invalid_subdomain.example.com/feed.atom"
      And I see the error "Url is invalid"

  Scenario: Creating a new feed with a winnow url
    Given I am logged in
    When I create a feed for "http://winnow.mindloom.org/feed.atom"
    Then I see the add feeds form
      And I see the error "Winnow generated feeds cannot be added to Winnow"
      And I see the url is set to "http://winnow.mindloom.org/feed.atom"

  Scenario: Creating a new feed with a winnow dev url
    Given I am logged in
    When I create a feed for "http://trunk.mindloom.org/feed.atom"
    Then I see the add feeds form
      And I see the error "Winnow generated feeds cannot be added to Winnow"
      And I see the url is set to "http://trunk.mindloom.org/feed.atom"
  
  # Scenario: Creating a new feed from the feed items page
  #   Given I am logged in
  #     And there is not a feed for "http://example.com/feed.atom"
  #   When I create a feed for "http://example.com/feed.atom" via ajax
  #   Then "http://example.com/feed.atom" is added to my sidebar
  # 
  # Scenario: Creating an existing feed from the feed items page
  # 
  # Scenario: Creating a new feed with a url from the feed items page
