require File.dirname(__FILE__) + '/../test_helper'

class FeedsTest < Test::Unit::SeleniumTestCase
  include SeleniumHelper
  fixtures :users, :feeds, :view_feed_states, :excluded_feeds
  
  def setup
    login
    open feeds_path
  end

  def test_changing_always_include_view_state
    dont_see_element "#always_include_feed_2.selected"
    
    click "always_include_feed_2"
    see_element "#always_include_feed_2.selected"
    
    refresh_and_wait
    see_element "#always_include_feed_2.selected"
    
    click "always_include_feed_2"
    dont_see_element "#always_include_feed_2.selected"
    
    refresh_and_wait
    dont_see_element "#always_include_feed_2.selected"
  end
  
  def test_changing_exclude_view_state
    dont_see_element "#exclude_feed_2.selected"
    
    click "exclude_feed_2"
    see_element "#exclude_feed_2.selected"
    
    refresh_and_wait
    see_element "#exclude_feed_2.selected"
    
    click "exclude_feed_2"
    dont_see_element "#exclude_feed_2.selected"
    
    refresh_and_wait
    dont_see_element "#exclude_feed_2.selected"
  end

  def test_globally_exclude_control_disables_view_state_controls
    click "always_include_feed_2"
    see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
    dont_see_element "#always_include_feed_2.disabled"
    dont_see_element "#exclude_feed_2.disabled"

    click "globally_exclude_feed_2"
    sleep 0.1
    dont_see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
    see_element "#always_include_feed_2.disabled"
    see_element "#exclude_feed_2.disabled"

    click "always_include_feed_2"
    dont_see_element "#always_include_feed_2.selected"

    click "exclude_feed_2"
    dont_see_element "#exclude_feed_2.selected"
    
    click "globally_exclude_feed_2"
    dont_see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
    dont_see_element "#always_include_feed_2.disabled"
    dont_see_element "#exclude_feed_2.disabled"    
    
    click "always_include_feed_2"
    see_element "#always_include_feed_2.selected"

    click "exclude_feed_2"
    see_element "#exclude_feed_2.selected"
    
    click "exclude_feed_2"
    dont_see_element "#exclude_feed_2.selected"
  end
  
  def test_toggling_between_view_states
    dont_see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
    
    click "always_include_feed_2"
    see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
    
    click "exclude_feed_2"
    dont_see_element "#always_include_feed_2.selected"
    see_element "#exclude_feed_2.selected"
    
    click "always_include_feed_2"
    see_element "#always_include_feed_2.selected"
    dont_see_element "#exclude_feed_2.selected"
  end
end
