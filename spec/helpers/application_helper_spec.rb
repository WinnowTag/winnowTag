# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
    
    it "should handle Feed" do
      feed = mock_model(Feed)
      globally_exclude_feed_check_box(feed).should have_tag("input[type=checkbox][onclick=?]", /.*\/feeds\/#{feed.id}.*/)
    end
    
    it "should handle Remote::Feed" do
      feed = mock_model(Remote::Feed)
      globally_exclude_feed_check_box(feed).should have_tag("input[type=checkbox][onclick=?]", /.*\/feeds\/#{feed.id}.*/)
    end
    
    it "is sets the checked status to true when already globally excluded" do
      current_user.stub!(:globally_excluded?).and_return(true)
      feed = mock_model(Feed)
      globally_exclude_feed_check_box(feed).should have_tag("input[checked=checked]")
    end
    
    it "is sets the checked status to false when not already globally excluded" do
      current_user.stub!(:globally_excluded?).and_return(false)
      feed = mock_model(Feed)
      globally_exclude_feed_check_box(feed).should_not have_tag("input[checked=checked]")
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
        show_flash_messages.should include(%|Message.add('#{name}', "Flash message for #{name}"|)
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
        :name => "Tag 1", :sort_name => sort_name, :user_id => user.id, :user => user, :positive_count => 0, :negative_count => 0, :feed_items_count => 0, :classifier_count => 0, :public? => false, :tag_subscriptions => []
      ))
    end
    
    it "creates a list with an li for each tag" do
      tags = [
        mock_tag(:name => "Tag 1"),
        mock_tag(:name => "Tag 2"),
        mock_tag(:name => "Tag 3")
      ]
      tag_filter_controls(tags, {}, :remove => :subscription).should have_tag("li", 3)
    end

    it "creates a filter control for a tag" do
      tag = mock_tag
      tag_filter_control(tag, :remove => :subscription).should have_tag("li##{dom_id(tag)}") do
        with_tag ".filter" do
          with_tag "span.name"
        end
      end
    end
    
    it "creates a filter control for a public tag" do
      tag_filter_control(mock_tag, :remove => :subscription).should have_tag("li.subscribed")
    end
    
    it "creates a filter control with a tooltip showing the trining and author information" do
      tag = mock_tag(:name => "aviation", :positive_count => 1, :negative_count => 2, :classifier_count => 3, :user => mock_model(User, :login => "craig", :public? => false))
      tag_filter_control(tag, :remove => :subscription).should have_tag("li[title=?]", "You're subscribed to 'aviation' by craig. 'aviation' finds 3 items using 1 positive examples and 2 negative examples.")
    end
  end
end
