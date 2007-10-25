require File.dirname(__FILE__) + '/../test_helper'

class TagSubscriptionTest < Test::Unit::TestCase
  def test_has_many_users
    assert_association TagSubscription, :belongs_to, :user
  end
  
  def test_has_many_tags
    assert_association TagSubscription, :belongs_to, :tag
  end
end
