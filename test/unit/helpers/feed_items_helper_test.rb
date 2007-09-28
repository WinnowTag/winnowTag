# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../test_helper'

class FeedItemsHelperTest < HelperTestCase
  fixtures :users, :bayes_classifiers, :roles, :roles_users, :tag_publications, :tag_groups, :feed_items
  include FeedItemsHelper
  attr_reader :current_user, :session
  self.use_transactional_fixtures = true

  def setup
    super
    @output = ""
    @current_user = users(:quentin)
    @min_train_count = 1
    @session = {}
    @view = View.new(:user => current_user)
    @feed_item_count = nil
  end

  def test_clean_html_should_strip_scripts
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<script>This is a script</script><h1>header</h1><p>content</p>"))
  end
  
  def test_clean_html_should_strip_styles
    assert_equal("<h1>header</h1><p>content</p>", clean_html("<style>div {font-size:64px;}</style><h1>header</h1><p>content</p>"))
  end
  
  def test_clean_html_should_strip_links
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<link rel="foo"><h1>header</h1><p>content</p>'))
  end
  
  def test_clean_html_should_strip_meta
    assert_equal("<h1>header</h1><p>content</p>", clean_html('<meta http-equiv="foo"><h1>header</h1><p>content</p>'))
  end
    
  # TODO: Remove if we are not using this, else update it to work with new filters
  # def test_tag_filters_uses_feed_item_count
  #   FeedItem.stubs(:count_with_filters).returns(50)
  #   @response.body = tag_filter_options
  #   assert_select("option[value = 'all']", "All Items (50)")
  # end
  
  # TODO: Remove if we are not using this, else update it to work with new filters
  # def test_tag_filters_uses_feed_item_count_instance_var_if_it_exists
  #   @feed_item_count = 100
  #   @response.body = tag_filter_options
  #   assert_select("option[value = 'all']", "All Items (100)")
  # end
  
  # TODO: Remove if we are not using this, else update it to work with new filters
  # def test_tag_filters
  #   tag = Tag.find_or_create_by_name('tag')
  #   tag.stubs(:count).returns(1)
  #   unwanted = Tag.find_or_create_by_name('unwanted')
  #   unwanted.stubs(:count).returns(10)
  #   @current_user.expects(:tags_with_count).with(:feed_filter => {:exclude => [], :include => [], :always_include => []}, :text_filter => nil).returns([tag, unwanted])
  #   @output = tag_filter_options
  #   assert_not_nil @output
  #   @output = HpricotTestHelper::DocumentOutput.new(@output)
  #   
  #   assert element("option[@value = 'tag']")
  #   assert element("option[@value = 'tag']").should_contain('tag (1)')
  # end

  # TODO: Remove if we are not using this, else update it to work with new filters
  # def test_tag_filters_with_classifier_tags
  #   tag = Tag.find_or_create_by_name('tag')
  #   tag.stubs(:count).returns(1)
  #   unwanted = Tag.find_or_create_by_name('unwanted')
  #   unwanted.stubs(:count).returns(10)
  #   @current_user.expects(:tags_with_count).with(:feed_filter => {:exclude => [], :include => [], :always_include => []}, :text_filter => nil).returns([tag, unwanted])
  #   @current_user.classifier.expects(:tags_with_count).with(:feed_filter => {:exclude => [], :include => [], :always_include => []}, :text_filter => nil).returns([tag, unwanted])
  #   
  #   @output = tag_filter_options
  #   assert_not_nil @output
  #   @output = HpricotTestHelper::DocumentOutput.new(@output)
  #   
  #   assert element("option[@value = 'tag']")
  #   assert element("option[@value = 'tag']").should_contain('tag (1/1)'), "tag text was #{element("option[@value = 'tag']").inner_text}"
  # end
    
  # TODO: Remove if we are not using this, else update it to work with new filters
  # def test_tag_filters_should_show_published_tags
  #   @response.body = tag_filter_options
  #   TagGroup.find_globals.each do |tg|
  #     assert_select("optgroup[label = '#{tg.name}']", 1, @response.body) do |elements|
  #       tg.tag_publications.each do |pub|
  #         assert_select(elements.first, "option[value = 'pub_tag:#{pub.id}']", "#{pub.publisher.login}:#{pub.tag} (0)", @response.body)
  #       end
  #     end
  #   end
  # end
  
  def test_tag_controls_helper_when_untagged
    @current_user.stubs(:tags).returns([Tag.find_or_create_by_name('tag1'), Tag.find_or_create_by_name('tag2'), Tag.find_or_create_by_name('tag3')])
    fi = FeedItem.find(1)
    @response.body = tag_controls(fi)
    
    assert_select('li.untagged', 0, @response.body)
  end
  
  def test_tag_controls_with_classifier_tags
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user, :tag => Tag.find_or_create_by_name('tag1'))
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user.classifier, :tag => Tag.find_or_create_by_name('tag2'))
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.user_tagging.tagged', true)
    assert_select('li#tag_control_for_tag2_on_feed_item_1.bayes_classifier_tagging.tagged', true)
  end
  
  def test_tag_controls_when_negative_tagging_exists
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user, :tag => Tag.find_or_create_by_name('tag1'), :strength => 0)
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user.classifier, :tag => Tag.find_or_create_by_name('tag1'))
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.bayes_classifier_tagging.user_tagging.negative_tagging', true, @response.body)
  end
  
  def test_tag_controls_when_positive_tagging_overrides_classifier_tagging
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user, :tag => Tag.find_or_create_by_name('tag1'))
    Tagging.create(:taggable => FeedItem.find(1), :tagger => @current_user.classifier, :tag => Tag.find_or_create_by_name('tag1'))
    @response.body = tag_controls(FeedItem.find(1))
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.tagged.user_tagging.bayes_classifier_tagging', true, @response.body)
  end
  
  def test_tag_controls_when_duplicate_tagging_exists
    feed_item = FeedItem.find(1)
    t1 = Tagging.new(:taggable => feed_item, :tag => Tag('tag1'), :tagger => current_user.classifier)
    t2 = Tagging.new(:taggable => feed_item, :tag => Tag('tag1'), :tagger => current_user.classifier)
    
    feed_item.expects(:taggings_by_taggers).with([current_user, current_user.classifier], :all_taggings => true).returns(
      [[Tag('tag1'), [t1, t2]]]
    )
    
    @response.body = tag_controls(feed_item)
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.bayes_classifier_tagging.tagged')
  end
  
  def test_tag_controls_with_borderline_item
    feed_item = FeedItem.find(1)
    t1 = Tagging.new(:taggable => feed_item, :tag => Tag('tag1'), :tagger => current_user.classifier, :strength => 0.89)
    
    feed_item.expects(:taggings_by_taggers).with([current_user, current_user.classifier], :all_taggings => true).returns(
      [[Tag('tag1'), [t1]]]
    )
    
    @response.body = tag_controls(feed_item)
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1.bayes_classifier_tagging.tagged.borderline', true, @response.body)
  end
  
  def test_tag_controls_should_not_display_item_below_threshold
    feed_item = FeedItem.find(1)
    t1 = Tagging.new(:taggable => feed_item, :tag => Tag('tag1'), :tagger => current_user.classifier, :strength => 0.85)
    
    feed_item.expects(:taggings_by_taggers).with([current_user, current_user.classifier], :all_taggings => true).returns(
      [[Tag('tag1'), [t1]]]
    )
    
    @response.body = tag_controls(feed_item)
    
    assert_select('li#tag_control_for_tag1_on_feed_item_1', false, @response.body)
  end
  
  def test_display_tags_for_feed_item
    fi = FeedItem.find(1)
    Tagging.create(:tagger => current_user, :taggable => fi, :tag => Tag.find_or_create_by_name('tag1'))
    Tagging.create(:tagger => current_user, :taggable => fi, :tag => Tag.find_or_create_by_name('tag2'))
    Tagging.create(:tagger => current_user.classifier, :taggable => fi, :tag => Tag.find_or_create_by_name('tag3'))
    @response.body = display_tags_for(fi)
    
    assert_select("span.user_tagging.tagged", "tag1", @response.body)
    assert_select("span.user_tagging.tagged", "tag2")
    assert_select("span.bayes_classifier_tagging.tagged", "tag3")
  end
  
  def test_display_borderline_tags
    fi = FeedItem.find(1)
    Tagging.create(:tagger => @current_user.classifier, :taggable => fi, :tag => Tag('tag'), :strength => 0.89)
    @response.body = display_tags_for(fi)

    assert_select("span.bayes_classifier_tagging.borderline", "tag")
  end
  
  def test_dont_display_tags_below_threshold
    feed_item = FeedItem.find(1)
    t1 = Tagging.create(:taggable => feed_item, :tag => Tag('tag1'), :tagger => current_user.classifier, :strength => 0.85)

    @response.body = display_tags_for(feed_item)
    
    assert_no_match(/tag1/, @response.body)
  end
  
  def test_is_item_unread_with_read_item
    assert !is_item_unread?( FeedItem.find(1) )
  end
  
  def test_is_item_unread_with_unread_item
    @current_user.unread_items.create(:feed_item_id => 1)
    assert is_item_unread?( FeedItem.find(1) )
  end
    
  def test_display_new_item_status_for_unread_item
    @current_user.unread_items.create(:feed_item_id => 1)
    @response.body = display_new_item_status(FeedItem.find(1))
    assert_select("a")
    assert_match(/addClassName\('read'\)/, @response.body)
  end
  
  def test_empty_new_item_status_for_item_not_in_new_item_list
    @response.body = display_new_item_status(FeedItem.find(1))
    assert_select("a")
    assert_match(/addClassName\('unread'\)/, @response.body)
  end
  
  # TODO: Update this to work with published tags
  # def test_display_published_tags_when_tag_filter_is_a_published_tag
  #   tag_filter = TagPublication.find(1)
  #   fi = FeedItem.find(1)
  #   tag_filter.taggings.create(:tag => tag_filter.tag, :taggable => fi)
  #   
  #   @view.add_tag :include, tag_filter
  #   @response.body = display_tags_for(fi)
  #   assert_select("span.tag_publication_tagging.tagged", "#{tag_filter.publisher.login}:#{tag_filter.tag.name}", "actual: " + @response.body)
  # end
  
  def test_clean_html_with_blank_value
    [nil, '', ' '].each do |value| 
      assert_nil clean_html(value)
    end
  end
  
  def test_clean_html_with_non_blank_value
    ["string", "<div>content</div>"].each do |value| 
      assert_not_nil clean_html(value)
    end
  end
  
  def test_feed_link_without_link
    feed_item = stub( :feed => stub( :title => "Feed Title", :link => nil ) )
    assert_equal "Feed Title", feed_link( feed_item )
  end
  
  def test_feed_link_with_link
    feed_item = stub( :feed => stub( :title => "Feed Title", :link => "http://example.com" ) )
    assert_equal '<a href="http://example.com">Feed Title</a>', feed_link( feed_item )
  end
  
  def test_feed_link_with_link_and_options
    feed_item = stub( :feed => stub( :title => "Feed Title", :link => "http://example.com" ) )
    assert_equal '<a href="http://example.com" target="_blank">Feed Title</a>', feed_link( feed_item, :target => "_blank" )
  end
end
