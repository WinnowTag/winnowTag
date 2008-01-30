require File.dirname(__FILE__) + '/../spec_helper'

describe "Login" do
  fixtures :users
  
  def test_successful_login
    login
    assert_match feed_items_url, get_location
  end
  
  def test_unsuccessful_login
    login "quentin", "wrong"
    assert_match login_url, get_location
    assert_equal "Invalid credentials. Please try again.", get_text("warning")
  end
end