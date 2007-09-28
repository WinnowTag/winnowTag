# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class TagGroupTest < Test::Unit::TestCase
  fixtures :tag_groups, :users

  # Replace this with your real tests.
  def test_find_global_groups
    assert_equal([tag_groups(:global1), tag_groups(:global2)], TagGroup.find_globals)
  end
  
  def test_new_global_tag_group_should_set_global_flag
    assert(TagGroup.new_global.global?, "new_global_tag_group should set global flag.")
  end
  
  def test_new_global_tag_group_should_set_publically_readable
    assert(TagGroup.new_global.publically_readable?, "new_global_tag_group should set publically readable flag.")
  end
  
  def test_new_global_tag_group_should_set_publically_writeable
    assert(TagGroup.new_global.publically_readable?, "new_global_tag_group should set publically writeable flag.")
  end
  
  def test_create_global_tag_group_should_set_global_flag
    assert(TagGroup.create_global.global?, "create_global_tag_group should set global flag.")
  end
  
  def test_create_global_tag_group_should_set_publically_readable
    assert(TagGroup.create_global.publically_readable?, "create_global_tag_group should set publically readable flag.")
  end
  
  def test_create_global_tag_group_should_set_publically_writeable
    assert(TagGroup.create_global.publically_readable?, "create_global_tag_group should set publically writeable flag.")
  end
  
  def test_create_global_tag_group_with_name
    assert_equal(TagGroup.create_global(:name => 'test').name, 'test')
  end

  def test_create_global_tag_group_with_description
    assert_equal(TagGroup.create_global(:description => 'desc').description, 'desc')
  end
  
  def test_global_tag_groups_should_have_unique_names
    TagGroup.create_global(:name => 'test')
    assert(TagGroup.create_global(:name => 'test').errors.on(:name), "Names should be unique for global tag groups.")
  end
end
