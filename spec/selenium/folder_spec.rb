# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "folders" do
  fixtures :users
  
  before(:each) do
    Folder.delete_all
    Feed.delete_all
    FeedSubscription.delete_all
    Tag.delete_all
    TagSubscription.delete_all
    
    @current_user = User.find_by_login("quentin")
    @existing_folder = Folder.create! :user_id => @current_user.id, :name => "existing folder"
    @example_feed = Feed.new :title => "Example Feed", :via => "http://example.com/atom"
    @example_feed.id = 1
    @example_feed.save!
    @another_example_feed = Feed.new :title => "Another Example Feed", :via => "http://another.example.com/atom"
    @another_example_feed.id = 2
    @another_example_feed.save!
    FeedSubscription.create! :feed_id => @another_example_feed.id, :user_id => @current_user.id
    @user = User.create! valid_user_attributes
    @private_tag = Tag.create! :name => "private tag", :user_id => @current_user.id
    @public_tag = Tag.create! :name => "public tag", :user_id => @user.id, :public => true
    TagSubscription.create! :tag_id => @public_tag.id, :user_id => @current_user.id

    login
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  it "can be created" do
    assert_not_visible "add_folder"

    page.click "css=#folders_section .add_link"
    assert_visible "add_folder"
    
    page.type "folder_name", "new folder"
    hit_enter "folder_name"
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

  # TODO 686 - auto complete is not triggered
  xit "can have feeds added" do
    assert_not_visible "css=#feeds_section .add_form"
  
    page.click "css=#feeds_section .add_link"
    assert_visible "css=#feeds_section .add_form"
     
    dont_see_element "#feed_#{@example_feed.id}"
     
    page.type "feed_title", @example_feed.title
    page.wait_for :wait_for => :ajax
    hit_enter "feed_title"
    page.wait_for :wait_for => :ajax
  
    see_element "#feed_#{@example_feed.id}"
  end
  
  it "can have feeds removed" do
    see_element "#feed_#{@another_example_feed.id}"
    page.click "css=#feed_#{@another_example_feed.id} .filter .remove"
    dont_see_element "#feed_#{@another_example_feed.id}"
  end
  
  # TODO 686 - auto complete is not triggered
  xit "can have private tags added"
  
  it "can have private tags removed" do
    see_element "#tag_#{@private_tag.id}"
    page.click "css=#tag_#{@private_tag.id} .filter .remove"
    dont_see_element "#tag_#{@private_tag.id}"
    page.wait_for :wait_for => :ajax
    page.confirmation.should include(@private_tag.name)
  end

  # TODO 686 - auto complete is not triggered
  xit "can have public tags added"
  
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

  # TODO 686 - droppable does not trigger
  xit "can have a feed moved to a custom folder" do
    dont_see_element "#folder_#{@existing_folder.id}_feed_items #feed_#{@another_example_feed.id}"

    page.click "css=#feeds_section .header .toggle_button"    
    page.click "css=#folders_section .header .toggle_button"    

    mouse_down "feed_#{@another_example_feed.id}"
    mouse_move_at "feed_#{@another_example_feed.id}", "0,-125"
    mouse_up "feed_#{@another_example_feed.id}"
    page.wait_for :wait_for => :ajax

    see_element "#folder_#{@existing_folder.id}_feed_items #feed_#{@another_example_feed.id}"
  end

  # TODO 686 - droppable does not trigger
  xit "can have a private tag moved to a custom folder"
  
  # TODO 686 - droppable does not trigger
  xit "can have a public tag moved to a custom folder"
  
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
