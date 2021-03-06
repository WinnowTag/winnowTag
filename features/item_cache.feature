Feature: Item Cache Access
  As a collector
  I want to update Winnow's item cache
  So that it can have some items.
  
  Scenario: Creating a new feed
    Given the feed entry at 'feed_entry.atom'
    When I add the feed
    Then there is 1 new feed in the system
    
  Scenario: Creating a new feed and adding some items to it.
    Given the feed entry at 'feed_entry.atom'
    And the item entry at 'item_entry1.atom'
    When I add the feed
    And I add the item to the feed
    Then there is 1 new feed in the system
    And  there is 1 new item in the system
    And  the new item belongs to the feed

  Scenario: Creating a new feed and adding an item to it and destroying the feed
    Given the feed entry at 'feed_entry.atom'
    And the item entry at 'item_entry1.atom'
    When I add the feed
    And I add the item to the feed
    And I destroy the feed
    Then there is 0 new feeds in the system
    And there is 0 new items in the system
    
  Scenario: Adding an item to an exising feed
    Given a feed in the system
    And the item entry at 'item_entry1.atom'
    When I add the item to the feed
    Then there is 1 new item in the system
    And the new item belongs to the feed

  Scenario: Deleting an existing item
    Given an item in the system
    When I destroy the item
		Then the system should return a 200
    And there is -1 new items in the system
    
  Scenario: Updating a feed item with the wrong id
    Given item 1 in the system
    And the item entry at 'item_entry1.atom'
    When I update the item
    Then there is 0 new items in the system
    And the item has not been updated
    
  Scenario: Updating a feed item with the right id
    Given an item in the system
    And the item entry at 'item_entry_existing.atom'
    When I update the item
    Then there is 0 new items in the system
    And the item has been updated
  
  Scenario: Sending invalid atom as an item
    Given a feed in the system
    When I submit invalid atom for an item
    Then the system should return a 400
  
  Scenario: Sending invalid atom as a feed
    When I submit invalid atom for a feed
    Then the system should return a 400
  