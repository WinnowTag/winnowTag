# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class TagSubscriptionTest < Test::Unit::TestCase
  def test_has_many_users
    assert_association TagSubscription, :belongs_to, :user
  end
  
  def test_has_many_tags
    assert_association TagSubscription, :belongs_to, :tag
  end
end
