# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class RandomBackgroundTest < Test::Unit::TestCase
  # Replace this with your real tests
  def test_generate_respects_limit
    RandomBackground.generate(2)
    assert_equal(2, RandomBackground.count)
  end
  
  def test_generate_fills_table
    RandomBackground.generate  
    assert_equal(FeedItem.count, RandomBackground.count)
  end
end
