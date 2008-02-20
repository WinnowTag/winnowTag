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
    it "needs to be tested"
  end
  
  describe "tag filter controls" do
    it "needs to be tested"
  end
end

  # def feed_filter_controls(feeds, options = {})
  #   content_tag :ul, feeds.map { |feed| feed_filter_control(feed, options) }.join, options.delete(:ul_options) || {}
  # end
  # 
  # def feed_filter_control(feed, options = {})   
  #   url  =  case options[:remove]
  #     when :subscription then subscribe_feed_path(feed, :subscribe => false)
  #     when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(feed))
  #   end
  #   html = link_to_function(image_tag("cross.png"), "itemBrowser.removeFilters({feed_ids: '#{feed.id}'}); this.up('li').remove(); #{remote_function(:url => url, :method => :put)}", :class => "remove") << " "
  #   html << link_to_function(feed.title, "itemBrowser.toggleSetFilters({feed_ids: '#{feed.id}'})", :class => "name", :title => "#{feed.feed_items.size} items in this feed")
  #   
  #   html =  content_tag(:div, html, :class => "show_feed_control")
  #   html << content_tag(:span, highlight(feed.title, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "feed_name") if options[:auto_complete]
  # 
  #   class_names = ["feed"]
  #   class_names << "draggable" if options[:draggable]
  #   html =  content_tag(:li, html, :id => dom_id(feed), :class => class_names.join(" "), :subscribe_url => subscribe_feed_path(feed, :subscribe => true))
  #   html << draggable_element(dom_id(feed), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }", :constraint => "'vertical'") if options[:draggable]
  #   html
  # end
  # 
  # def tag_filter_controls(tags, options = {})
  #   content_tag :ul, tags.map { |tag| tag_filter_control(tag, options) }.join, options.delete(:ul_options) || {}
  # end
  # 
  # def tag_filter_control(tag, options = {})
  #   if options[:remove] == :subscription && current_user == tag.user
  #     options = options.except(:remove)
  #     options[:remove] = :sidebar
  #   end
  #   url  =  case options[:remove]
  #     when :subscription then subscribe_tag_path(tag, :subscribe => false)
  #     when :sidebar      then sidebar_tag_path(tag, :sidebar => false)
  #     when Folder        then remove_item_folder_path(options[:remove], :item_id => dom_id(tag))
  #   end
  #   html =  link_to_function(image_tag("cross.png"), "itemBrowser.removeFilters({tag_ids: '#{tag.id}'}); this.up('li').remove(); #{remote_function(:url => url, :method => :put)}", :class => "remove") << " "
  #   html << image_tag("pencil.png", :id => dom_id(tag, "edit"), :class => "edit") if current_user == tag.user
  #   html << link_to_function(tag.name, "itemBrowser.toggleSetFilters({tag_ids: '#{tag.id}'})", :class => "name", :id => dom_id(tag, "name"), :title => tag.user_id == current_user.id ? nil :  "from #{tag.user.display_name}")
  #   html << in_place_editor(dom_id(tag, "name"), :url => tag_path(tag), :options => "{method: 'put'}", :param_name => "tag[name]",
  #             :external_control => dom_id(tag, "edit"), :external_control_only => true, :click_to_edit_text => "", 
  #             :on_enter_hover => "", :on_leave_hover => "", :on_complete => "",
  #             :save_control => false, :cancel_control => false) if tag.user_id == current_user.id
  #   
  #   html =  content_tag(:div, html, :class => "show_tag_control")
  #   html << content_tag(:span, highlight(tag.name, options[:auto_complete], '<span class="highlight">\1</span>'), :class => "tag_name") if options[:auto_complete]
  #   
  #   class_names = ["tag"]
  #   class_names << "public" if tag.user_id != current_user.id
  #   class_names << "draggable" if options[:draggable]
  #   url  =  case options[:remove]
  #     when :subscription then subscribe_tag_path(tag, :subscribe => true)
  #     when :sidebar      then sidebar_tag_path(tag, :sidebar => true)
  #   end
  #   html =  content_tag(:li, html, :id => dom_id(tag), :class => class_names.join(" "), :subscribe_url => url)
  #   html << draggable_element(dom_id(tag), :scroll => "'sidebar'", :ghosting => true, :revert => true, :reverteffect => "function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }", :constraint => "'vertical'") if options[:draggable]
  #   html
  # end
  # 
