# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "folders" do
  before(:each) do
    @current_user = Generate.user!
    @existing_folder = Folder.create! :user_id => @current_user.id, :name => "existing folder"
    @example_feed = Feed.new :title => "Example Feed", :via => "http://example.com/atom", :uri => "urn:test:example1"
    @example_feed.id = 1
    @example_feed.save!
    @another_example_feed = Feed.new :title => "Another Example Feed", :via => "http://another.example.com/atom", :uri => "urn:test:example2"
    @another_example_feed.id = 2
    @another_example_feed.save!
    FeedSubscription.create! :feed_id => @another_example_feed.id, :user_id => @current_user.id
    @user = Generate.user!
    @private_tag = Tag.create! :name => "private tag", :user_id => @current_user.id
    @public_tag = Tag.create! :name => "public tag", :user_id => @user.id, :public => true
    TagSubscription.create! :tag_id => @public_tag.id, :user_id => @current_user.id

    @private_tag_not_in_sidebar = Tag.create! :name => "private tag not in sidebar", :user_id => @current_user.id, :show_in_sidebar => false
    @public_tag_not_in_sidebar = Tag.create! :name => "public tag not in sidebar", :user_id => @user.id, :public => true

    login @current_user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
    page.window_maximize
  end
  
  it "can be created" do
    assert_not_visible "css=#folders_section .add_form"

    page.click "css=#folders_section .add_link"
    assert_visible "css=#folders_section .add_form"
    
    page.type "folder_name", "new folder"
    page.submit "add_folder_form"
    page.wait_for :wait_for => :ajax
    
    new_folder = Folder.find_by_name("new folder")
    see_element "#folder_#{new_folder.id}"
  end
  
  it "can be renamed" do
    dont_see_element "#folder_#{@existing_folder.id} input"
    page.click "css=#folder_#{@existing_folder.id} .edit"
    page.prompt
  end
  
  it "can be destroyed" do
    see_element "#folder_#{@existing_folder.id}"

    page.click "css=#folder_#{@existing_folder.id} .remove"
    page.confirmation.should == "Are you sure?"
    page.wait_for :wait_for => :ajax
    
    dont_see_element "#folder_#{@existing_folder.id}"
  end  

  it "can have feeds added" do
    assert_not_visible "css=#feeds_section .add_form"
  
    page.click "css=#feeds_section .add_link"
    assert_visible "css=#feeds_section .add_form"
     
    dont_see_element "#feed_#{@example_feed.id}"
     
    # Need to use type and type_keys here.  In IE
    # type_keys just fires the keyPress events, it
    # doesn't set the element value, which is needed
    # by the Autocomplete handler.
    #
    page.type "feed_title", @example_feed.title
    page.type_keys "feed_title", @example_feed.title
    page.wait_for :wait_for => :ajax
    page.wait_for :wait_for => :element, :element => "css=#feed_title_auto_complete #feed_#{@example_feed.id}"
    hit_enter "feed_title"
    page.wait_for :wait_for => :ajax
    see_element "#feed_#{@example_feed.id}"
  end
  
  it "can have feeds removed" do
    see_element "#feed_#{@another_example_feed.id}"
    page.click "css=#feed_#{@another_example_feed.id} .filter .remove"
    dont_see_element "#feed_#{@another_example_feed.id}"
  end
  
  it "can have private tags added" do
    assert_not_visible "css=#tags_section .add_form"
  
    page.click "css=#tags_section .add_link"
    assert_visible "css=#tags_section .add_form"
     
    dont_see_element "#tag_#{@private_tag_not_in_sidebar.id}"
     
    page.type "tag_name", @private_tag_not_in_sidebar.name
    page.type_keys "tag_name", @private_tag_not_in_sidebar.name
    page.wait_for :wait_for => :ajax
    page.wait_for :wait_for => :element, :element => "css=#tag_name_auto_complete #tag_#{@private_tag_not_in_sidebar.id}"
    hit_enter "tag_name"
    page.wait_for :wait_for => :ajax
    see_element "#tag_filters #tag_#{@private_tag_not_in_sidebar.id}"
  end
  
  it "can have private tags removed" do
    see_element "#tag_#{@private_tag.id}"
    page.click "css=#tag_#{@private_tag.id} .filter .remove"
    dont_see_element "#tag_#{@private_tag.id}"
    page.wait_for :wait_for => :ajax
    page.confirmation.should include(@private_tag.name)
  end

  it "can have public tags added" do
    assert_not_visible "css=#tags_section .add_form"
  
    page.click "css=#tags_section .add_link"
    assert_visible "css=#tags_section .add_form"
     
    dont_see_element "#tag_#{@public_tag_not_in_sidebar.id}"
     
    page.type "tag_name", @public_tag_not_in_sidebar.name
    page.type_keys "tag_name", @public_tag_not_in_sidebar.name
    page.wait_for :wait_for => :ajax
    page.wait_for :wait_for => :element, :element => "css=#tag_name_auto_complete #tag_#{@public_tag_not_in_sidebar.id}"
    hit_enter "tag_name"
    page.wait_for :wait_for => :ajax
    see_element "#tag_filters #tag_#{@public_tag_not_in_sidebar.id}"
  end
  
  it "can have public tags removed" do
    see_element "#tag_#{@public_tag.id}"
    page.click "css=#tag_#{@public_tag.id} .filter .remove"
    dont_see_element "#tag_#{@public_tag.id}"      
  end
  
  it "can have private tags renamed" do
    dont_see_element "#tag_#{@private_tag.id} input"
    page.click "css=#tag_#{@private_tag.id} .edit"
    page.prompt
  end
  
  it "cannot rename public tags" do
    dont_see_element "#tag_#{@public_tag.id} .edit"
  end

  it "can have a feed moved to a custom folder" do
    dont_see_element "#folder_#{@existing_folder.id}_feed_items #feed_#{@another_example_feed.id}"

    page.click "css=#feeds_section .header .toggle_button"    
    page.click "css=#folders_section .header .toggle_button"    
    
    page.drag_and_drop_to_object "feed_#{@another_example_feed.id}", "folder_#{@existing_folder.id}"
    page.wait_for :wait_for => :ajax

    see_element "#folder_#{@existing_folder.id} #feed_#{@another_example_feed.id}"
  end

  it "can have a private tag moved to a custom folder" do
    dont_see_element "#folder_#{@existing_folder.id}_tags #tag_#{@private_tag.id}"

    page.click "css=#tags_section .header .toggle_button"    
    page.click "css=#folders_section .header .toggle_button"    

    page.drag_and_drop_to_object "tag_#{@private_tag.id}", "folder_#{@existing_folder.id}"
    page.wait_for :wait_for => :ajax

    see_element "#folder_#{@existing_folder.id} #tag_#{@private_tag.id}"
  end
  
  it "can have a public tag moved to a custom folder" do
    dont_see_element "#folder_#{@existing_folder.id}_tags #tag_#{@public_tag.id}"

    page.click "css=#tags_section .header .toggle_button"    
    page.click "css=#folders_section .header .toggle_button"    

    page.drag_and_drop_to_object "tag_#{@public_tag.id}", "folder_#{@existing_folder.id}"
    page.wait_for :wait_for => :ajax

    see_element "#folder_#{@existing_folder.id} #tag_#{@public_tag.id}"
  end
  
  it "can open tags folder" do
    assert_not_visible "css=#tag_filters"
    page.click "css=#tags_section .header .toggle_button"
    assert_visible "css=#tag_filters"
  end
  
  it "can open feeds folder" do
    assert_not_visible "css=#feed_filters"
    page.click "css=#feeds_section .header .toggle_button"
    assert_visible "css=#feed_filters"
  end
  
  it "can open custom folder" do
    assert_not_visible "css=#folder_#{@existing_folder.id}_tag_items"
    assert_not_visible "css=#folder_#{@existing_folder.id}_feed_items"
    page.click "css=#folders_section .header .toggle_button"
    page.click "css=#folder_#{@existing_folder.id} .header .toggle_button"
    assert_visible "css=#folder_#{@existing_folder.id}_tag_items"
    assert_visible "css=#folder_#{@existing_folder.id}_feed_items"
  end
end
