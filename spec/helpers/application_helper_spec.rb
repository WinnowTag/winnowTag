# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  include ApplicationHelper

  attr_reader :current_user
  
  before(:each) do
    @current_user = Generate.user!
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
    
    before(:each) do
      @setting = Setting.create! :name => "Help", :value => {
        "default" => "http://docs.mindloom.org/wiki/WinnowHelp",
        "feed_items" => {
          "index" => "http://docs.mindloom.org/wiki/WinnowHelp:Items_page"
        }
      }.to_yaml
    end

    it "maps a controller + action to a specific wiki page" do
      @controller_name = "feed_items"
      @action_name = "index"
      help_path.should == "http://docs.mindloom.org/wiki/WinnowHelp:Items_page"
    end
    
    it "maps a controller + action to the default wiki page" do
      @controller_name = "feeds"
      @action_name = "fake"
      help_path.should == "http://docs.mindloom.org/wiki/WinnowHelp"
    end
    
    it "handless nil yaml" do
      @setting.update_attribute :value, nil
      help_path.should be_nil
    end
    
    it "handless malformed yaml" do
      @setting.update_attribute :value, "items:\nthings:"
      help_path.should be_nil
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
    [:notice, :warning, :error].each do |name|
      it "prints javascript for flash #{name}" do
        flash[name] = "Flash message for #{name}"
        show_flash_messages.should include(%|Message.add('#{name}', "Flash message for #{name}")|)
      end
    end
  end
  
  describe "section_open?" do
    # Need to fix rspec for this
    xit "is true when cookies[id] is set to a truthy value" do
      cookies["tags"] = "true"
      section_open?("tags").should be_true
    end
    
    xit "is false when cookies[id] is set to a falsy value" do
      ["", "false"].each do |falsy_value|
        cookies["tags"] = falsy_value
        section_open?("tags").should be_false
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

  describe "tag filter controls" do    
    def mock_tag(stubs = {})
      user = stubs[:user] || mock_model(User, :login => "mark")
      sort_name = (stubs[:name] || "Tag 1").to_s.downcase.gsub(/[^a-zA-Z0-9]/, '')
      mock_model(Tag, stubs.reverse_merge(
        :name => "Tag 1", :sort_name => sort_name, :user_id => user.id, :user => user, :positive_count => 0, :negative_count => 0, :classifier_count => 0
      ))
    end
    
    it "creates a list with an li for each tag" do
      tags = [
        mock_tag(:name => "Tag 1"),
        mock_tag(:name => "Tag 2"),
        mock_tag(:name => "Tag 3")
      ]
      tag_filter_controls(tags, :remove => :subscription).should have_tag("ul") do
        with_tag("li", 3)
      end
    end

    it "creates a filter control for a tag" do
      tag = mock_tag
      tag_filter_control(tag, :remove => :subscription).should have_tag("li##{dom_id(tag)}") do
        with_tag ".filter" do
          with_tag "a.remove[onclick=?]", /.*#{Regexp.escape("itemBrowser.removeFilters({tag_ids: '#{tag.id}'})")}.*/
          with_tag "span.name"
        end
      end
    end
    
    it "creates a filter control for a tag with the remove link for a subscription" do
      tag = mock_tag
      tag_filter_control(tag, :remove => :subscription).should have_tag("li[subscribe_url=?]", subscribe_tag_path(tag, :subscribe => true)) do
        with_tag("a.remove[onclick=?]", /.*#{Regexp.escape(unsubscribe_tag_path(tag))}.*/)
      end
    end
    
    it "creates a filter control for a tag with the remove link for a sidebar" do
      tag = mock_tag
      tag_filter_control(tag, :remove => :sidebar).should have_tag("li[subscribe_url=?]", sidebar_tag_path(tag, :sidebar => true)) do
        with_tag("a.remove[onclick=?]", /.*#{Regexp.escape(sidebar_tag_path(tag, :sidebar => "false"))}.*/)
      end
    end
    
    it "creates a filter control for a tag with the remove link for a subscription and current_user" do
      tag = mock_tag(:user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :remove => :subscription).should have_tag("a.remove[onclick=?]", /.*#{Regexp.escape(sidebar_tag_path(tag, :sidebar => "false"))}.*/)
    end
    
    it "creates a filter control for a tag with a span for autocomplete" do
      tag_filter_control(mock_tag, :remove => :subscription, :auto_complete => "ed").should have_tag("span.auto_complete_name")
    end
    
    it "creates a filter control for a public tag" do
      tag_filter_control(mock_tag, :remove => :subscription).should have_tag("li.public")
    end
    
    it "creates a filter control with a tooltip showing the trining and author information" do
      tag = mock_tag(:positive_count => 1, :negative_count => 2, :classifier_count => 3, :user => mock_model(User, :login => "craig"))
      tag_filter_control(tag, :remove => :subscription).should have_tag("li[title=?]", "From craig, Positive: 1, Negative: 2, Automatic: 3")
    end
    
    it "creates a filter control without an edit control for public tags" do
      tag_filter_control(mock_tag, :remove => :subscription).should_not have_tag("img.edit")
    end
    
    it "creates a filter control with an edit control for private tags if editable" do
      tag = mock_tag(:user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :editable => true, :remove => :subscription).should have_tag(".edit")
    end

    it "creates a filter control without an edit control for private tags if not editable" do
      tag = mock_tag(:user_id => current_user.id, :user => current_user)
      tag_filter_control(tag, :editable => false, :remove => :subscription).should_not have_tag(".edit")
    end
  end
end
