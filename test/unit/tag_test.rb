require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  fixtures :tags

  # Replace this with your real tests.
  def test_cant_create_duplicate_tags
    assert_valid Tag.create(:name => 'foo')
    assert_invalid Tag.new(:name => 'foo')
  end
  
  def test_cant_create_empty_tags
    assert_invalid Tag.new(:name => '')
  end
  
  def test_case_insensitive
    tag1 = Tag.find_or_create_by_name('TAG1')
    tag2 = Tag.find_or_create_by_name('tag1')
    assert_not_equal tag1, tag2
  end
  
  def test_tag_function
    tag = Tag('tag1')
    assert tag.is_a?(Tag)
    assert_equal 'tag1', tag.name
    assert !tag.new_record?
    
    tag2 = Tag(tag)
    assert_equal tag, tag2
  end
  
  def test_tag_to_s_returns_name
    tag = Tag('tag1')
    assert_equal('tag1', tag.to_s)
  end
  
  def test_tag_to_param_returns_name
    tag = Tag('tag1')
    assert_equal('tag1', tag.to_param)
  end
  
  def test_sorting
    tag1 = Tag('aaa')
    tag2 = Tag('bbb')
    assert_equal([tag1, tag2], [tag1, tag2].sort)
    assert_equal([tag1, tag2], [tag2, tag1].sort)
  end
  
  def test_sorting_is_case_insensitive
    tag1 = Tag('aaa')
    tag2 = Tag('Abb')
    assert_equal([tag1, tag2], [tag1, tag2].sort)
    assert_equal([tag1, tag2], [tag2, tag1].sort)
  end
  
  def test_sorting_with_none_tag_raises_exception
    tag = Tag('tag')
    assert_raise(ArgumentError) { tag <=> 42 }
  end
end
