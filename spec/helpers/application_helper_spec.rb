# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  attr_reader :current_user
  
  before(:each) do
    @current_user = mock_model(User, valid_user_attributes)
  end
  
  describe "#globally_exclude_check_box" do
    before(:each) do
      current_user.stub!(:globally_excluded?).and_return(false)
    end
    
    it "should handle Tag" do
      tag = mock_model(Tag)
      globally_exclude_check_box(tag).should have_tag("input[type=checkbox][onclick=?]", /.*\/tags\/#{tag.id}.*/)
    end
    
    it "should handle Feed" do
      feed = mock_model(Feed)
      globally_exclude_check_box(feed).should have_tag("input[type=checkbox][onclick=?]", /.*\/feeds\/#{feed.id}.*/)
    end
    
    it "should handle Remote::Feed" do
      feed = mock_model(Remote::Feed)
      globally_exclude_check_box(feed).should have_tag("input[type=checkbox][onclick=?]", /.*\/feeds\/#{feed.id}.*/)
    end
    
    it "is sets the checked status to true when already globally excluded" do
      current_user.stub!(:globally_excluded?).and_return(true)
      tag = mock_model(Tag)
      globally_exclude_check_box(tag).should have_tag("input[checked=checked]")
    end
    
    it "is sets the checked status to false when not already globally excluded" do
      current_user.stub!(:globally_excluded?).and_return(false)
      tag = mock_model(Tag)
      globally_exclude_check_box(tag).should_not have_tag("input[checked=checked]")
    end
  end
    
  describe "#help_path" do
    def controller_name; @controller_name; end
    def action_name; @action_name; end

    it "points to the same controller on docs.mindloom.org" do
      @controller_name = "feeds"
      help_path.should == "http://docs.mindloom.org/feeds"
    end

    it "points to the same controller/action on docs.mindloom.org" do
      @controller_name = "tags"
      @action_name = "public"
      help_path.should == "http://docs.mindloom.org/tags/public"
    end
  end
  
  describe "tab selected" do
    def controller_name; @controller_name; end
    def action_name; @action_name; end

    it "returns selected when the controller matches" do
      @controller_name = "feeds"
      tab_selected("feeds").should == "selected"
    end
    
    it "returns nil when the controller doesnt match" do
      @controller_name = "tags"
      tab_selected("feeds").should be_nil
    end

    it "returns selected when the controller and action matches" do
      @controller_name = "feeds"
      @action_name = "index"
      tab_selected("feeds", "index").should == "selected"
    end
    
    it "returns nil when the controller matches but action doesnt match" do
      @controller_name = "tags"
      @action_name = "index"
      tab_selected("tags", "public").should be_nil
    end
  end
  
  describe "show flash" do
    [:notice, :warning, :error, :confirm].each do |name|
      it "prints divs for flash #{name}" do
        flash[name] = "Flash message for #{name}"
        show_flash.should have_tag("div##{name}", "Flash message for #{name}")
      end
    end
    
    it "creates the div hidden when the flash is blank" do
      show_flash.should have_tag("div#notice[style=display:none]")
    end
  end

  describe "show_sidebar?" do
    it "is true when cookies[:show_sidebar] is set to a truthy value" do
      ["", "true"].each do |truthy_value|
        cookies[:show_sidebar] = truthy_value
        show_sidebar?.should be_true
      end
    end
    
    xit "is false when cookies[:show_sidebar] is set to a falsy value" do
      cookies[:show_sidebar] = "false"
      show_sidebar?.should be_false
    end
  end
  
  describe "open_folder?" do
    xit "is true when cookies[folder] is set to a truthy value" do
      folder = mock_model(Folder)
      cookies[dom_id(folder)] = "true"
      open_folder?(folder).should be_true
    end
    
    it "is false when cookies[folder] is set to a falsy value" do
      ["", "false"].each do |falsy_value|
        folder = mock_model(Folder)
        cookies[dom_id(folder)] = falsy_value
        open_folder?(folder).should be_false
      end
    end
  end
  
  describe "open_tags?" do
    xit "is true when cookies[:tags] is set to a truthy value" do
      cookies[:tags] = "true"
      open_tags?.should be_true
    end
    
    it "is false when cookies[:tags] is set to a falsy value" do
      ["", "false"].each do |falsy_value|
        cookies[:tags] = falsy_value
        open_tags?.should be_false
      end
    end
  end
  
  describe "open_feeds?" do
    xit "is true when cookies[:feeds] is set to a truthy value" do
      cookies[:feeds] = "true"
      open_feeds?.should be_true
    end
    
    it "is false when cookies[:feeds] is set to a falsy value" do
      ["", "false"].each do |falsy_value|
        cookies[:feeds] = falsy_value
        open_feeds?.should be_false
      end
    end
  end

  describe "is_admin?" do
    it "returns true when the current user has the admin role" do
      current_user.should_receive(:has_role?).with('admin').and_return(true)
      is_admin?.should be_true
    end
    
    it "returns false when the current user does not have the admin role" do
      current_user.should_receive(:has_role?).with('admin').and_return(false)
      is_admin?.should be_false
    end
  end

  describe "tag_name_with_tooltip" do
    it "creates a span with the tag name" do
      tag = mock_model(Tag, :name => "tag1", :user_id => current_user.id)
      tag_name_with_tooltip(tag).should have_tag("span", "tag1")
    end
    
    it "creates a span with no title when the tag is the current users" do
      tag = mock_model(Tag, :name => "tag1", :user_id => current_user.id)
      tag_name_with_tooltip(tag).should_not have_tag("span[title]")
    end
    
    it "creates a span with a title containing the tag owners name when the tags is not the current users" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "tag1", :user_id => user.id, :user => user)
      tag_name_with_tooltip(tag).should have_tag("span[title=?]", "from Mark")
    end
  end
  
  describe "feed filter controls" do
    it "creates a list with an li for each feed" do
      feeds = [
        mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1)),
        mock_model(Feed, :title => "Feed 2", :feed_items => stub("feed_items", :size => 2)),
        mock_model(Feed, :title => "Feed 3", :feed_items => stub("feed_items", :size => 3))
      ]
      feed_filter_controls(feeds, :remove => :subscription).should have_tag("ul") do
        with_tag("li", 3)
      end
    end
    
    it "creates a filter control for a feed" do
      feed = mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1))
      feed_filter_control(feed, :remove => :subscription).should have_tag("li##{dom_id(feed)}.feed[subscribe_url=?]", subscribe_feed_path(feed, :subscribe => true)) do
        with_tag "div.show_feed_control" do
          with_tag "a.remove[onclick=?]", /#{Regexp.escape("itemBrowser.removeFilters({feed_ids: '#{feed.id}'})")}.*/
          with_tag "a.name[onclick=?]", /#{Regexp.escape("itemBrowser.toggleSetFilters({feed_ids: '#{feed.id}'})")}.*/
        end
      end
    end
    
    it "creates a filter control for a feed with the remove link for a subscription" do
      feed = mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1))
      feed_filter_control(feed, :remove => :subscription).should have_tag("a.remove[onclick=?]", /.*#{Regexp.escape(subscribe_feed_path(feed, :subscribe => false))}.*/)
    end
    
    it "creates a filter control for a feed with the remove link for a subscription" do
      feed = mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1))
      folder = mock_model(Folder)
      feed_filter_control(feed, :remove => folder).should have_tag("a.remove[onclick=?]", /.*#{Regexp.escape(remove_item_folder_path(folder, :item_id => dom_id(feed)))}.*/)
    end
    
    it "creates a filter control for a feed with a span for autocomplete" do
      feed = mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1))
      feed_filter_control(feed, :remove => :subscription, :auto_complete => "ed").should have_tag("span.feed_name")
    end
    
    it "creates a filter control for a feed with draggable controls" do
      feed = mock_model(Feed, :title => "Feed 1", :feed_items => stub("feed_items", :size => 1))
      feed_filter_control(feed, :remove => :subscription, :draggable => true).should have_tag("li.draggable")
      feed_filter_control(feed, :remove => :subscription, :draggable => true).should have_tag("script", /.*Draggable.*/)
    end
  end
  
  describe "tag filter controls" do
    it "creates a list with an li for each tag" do
      user = mock_model(User, :display_name => "Mark")
      tags = [
        mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user),
        mock_model(Tag, :name => "Tag 2", :user_id => user.id, :user => user),
        mock_model(Tag, :name => "Tag 3", :user_id => user.id, :user => user)
      ]
      tag_filter_controls(tags, :remove => :subscription).should have_tag("ul") do
        with_tag("li", 3)
      end
    end

    it "creates a filter control for a tag" do
      tag = mock_model(Tag, :name => "Tag 1", :user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("li##{dom_id(tag)}.tag") do
        with_tag "div.show_tag_control" do
          with_tag "a.remove[onclick=?]", /#{Regexp.escape("itemBrowser.removeFilters({tag_ids: '#{tag.id}'})")}.*/
          with_tag "a.name[onclick=?]", /#{Regexp.escape("itemBrowser.toggleSetFilters({tag_ids: '#{tag.id}'})")}.*/
        end
      end
    end
    
    it "creates a filter control for a tag with the remove link for a subscription" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("li[subscribe_url=?]", subscribe_tag_path(tag, :subscribe => true)) do
        with_tag("a.remove[onclick=?]", /.*#{Regexp.escape(subscribe_tag_path(tag, :subscribe => false))}.*/)
      end
    end
    
    it "creates a filter control for a tag with the remove link for a subscription" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      folder = mock_model(Folder)
      tag_filter_control(tag, :remove => folder).should have_tag("a.remove[onclick=?]", /.*#{Regexp.escape(remove_item_folder_path(folder, :item_id => dom_id(tag)))}.*/)
    end
    
    it "creates a filter control for a tag with the remove link for a sidebar" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :sidebar).should have_tag("li[subscribe_url=?]", sidebar_tag_path(tag, :sidebar => true)) do
        with_tag("a.remove[onclick=?]", /.*#{Regexp.escape(sidebar_tag_path(tag, :sidebar => false))}.*/)
      end
    end
    
    it "creates a filter control for a tag with the remove link for a subscription and current_user" do
      tag = mock_model(Tag, :name => "Tag 1", :user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("a.remove[onclick=?]", /.*#{Regexp.escape(sidebar_tag_path(tag, :sidebar => false))}.*/)
    end
    
    it "creates a filter control for a tag with a span for autocomplete" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :subscription, :auto_complete => "ed").should have_tag("span.tag_name")
    end
    
    it "creates a filter control for a tag with draggable controls" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :subscription, :draggable => true).should have_tag("li.draggable")
      tag_filter_control(tag, :remove => :subscription, :draggable => true).should have_tag("script", /.*Draggable.*/)
    end
    
    it "creates a filter control for a public tag" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("li.public") do
        with_tag "a.name[title=?]", "from Mark"
      end
    end
    
    it "creates a filter control without an edit control for public tags" do
      user = mock_model(User, :display_name => "Mark")
      tag = mock_model(Tag, :name => "Tag 1", :user_id => user.id, :user => user)
      tag_filter_control(tag, :remove => :subscription).should_not have_tag("img.edit")
    end
    
    it "creates a filter control with and edit control for private tags" do
      tag = mock_model(Tag, :name => "Tag 1", :user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("img.edit")
      tag_filter_control(tag, :remove => :subscription).should have_tag("script", /.*InPlaceEditor.*/)
    end
  end
end
