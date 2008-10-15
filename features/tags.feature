Feature: Tag Feeds
  As a Feed consumer
  I want to access feeds for each tag
  So that I can read them
  
  Scenario: Accessing a feed for a public tag
    Given a public tag in the system
    When I access /username/tags/tagname.atom  
    Then the response is 200
    And the body is parseable by ratom
    And the content type is atom

  Scenario: Accessing the tag index as a feed
    When I access /tags.atom
    Then the response is 200
    And the body is parseable by ratom
    And the content type is atom
