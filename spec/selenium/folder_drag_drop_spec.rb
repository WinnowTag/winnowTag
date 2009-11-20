# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

require File.dirname(__FILE__) + '/../spec_helper'

module FolderHelpers
  
  def dont_see_feed_in_folder(feed, folder)
    dont_see_element "#folder_#{folder.id}_feed_items #feed_#{feed.id}"
  end

  def see_feed_in_folder(feed, folder)
    see_element "#folder_#{folder.id}_feed_items #feed_#{feed.id}"
  end

  def dont_see_tag_in_folder(tag, folder)
    dont_see_element "#folder_#{folder.id}_tag_items #tag_#{tag.id}"
  end

  def see_tag_in_folder(tag, folder)
    see_element "#folder_#{folder.id}_tag_items #tag_#{tag.id}"
  end

  def open_tags_section
    page.click "css=#tags_section .header .toggle_button"
  end

  def open_feeds_section
    page.click "css=#feeds_section .header .toggle_button"
  end

  def open_folders_section
    page.click "css=#folders_section .header .toggle_button"
  end

  def select_tag(tag)
    page.click "css=#tags_section #name_tag_#{tag.id}"
    page.wait_for :wait_for => :ajax
  end

  def select_tags(*tags)
    tags.each do |tag|
      multi_select_click "css=#tags_section #name_tag_#{tag.id}"
      page.wait_for :wait_for => :ajax
    end
  end

  def select_tags_in_folder(folder, *tags)
    tags.each do |tag|
      multi_select_click "css=#folder_#{folder.id}_tag_items #name_tag_#{tag.id}"
      page.wait_for :wait_for => :ajax
    end
  end

  def select_feed(feed)
    page.click "css=#feeds_section #name_feed_#{feed.id}"
    page.wait_for :wait_for => :ajax
  end

  def select_feeds(*feeds)
    feeds.each do |feed|
      multi_select_click "css=#feeds_section #name_feed_#{feed.id}"
      page.wait_for :wait_for => :ajax
    end
  end

  def select_feeds_in_folder(folder, *feeds)
    feeds.each do |feed|
      multi_select_click "css=#folder_#{folder.id}_feed_items #name_feed_#{feed.id}"
      page.wait_for :wait_for => :ajax
    end
  end
  
end

describe "dragging and dropping feeds and tags to folders" do
  
  include FolderHelpers

  before(:each) do
    @current_user = Generate.user!
    @user = Generate.user!

    @folder_1 = Folder.create! :user => @current_user, :name => "Folder 1"

    @feed_1 = Feed.create! :title => "Feed 1", :via => "http://example.com/atom", :uri => "urn:test:example1"
    FeedSubscription.create! :feed => @feed_1, :user => @current_user

    @feed_2 = Feed.create! :title => "Feed 2", :via => "http://another.example.com/atom", :uri => "urn:test:example2"
    FeedSubscription.create! :feed => @feed_2, :user => @current_user

    @tag_1 = Tag.create! :name => "tag 1", :user => @current_user
    @tag_2 = Tag.create! :name => "tag 2", :user => @current_user

    @public_tag = Tag.create! :name => "public tag", :user => @user, :public => true
    TagSubscription.create! :tag => @public_tag, :user => @current_user

    login @current_user
    
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
    page.window_maximize

    open_folders_section
  end

  context "when dragging one and no others are selected" do

    it "copies a feed to a folder" do
      dont_see_feed_in_folder(@feed_1, @folder_1)

      open_feeds_section

      page.drag_and_drop_to_object "feed_#{@feed_1.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_feed_in_folder(@feed_1, @folder_1)
    end

    it "copies a private tag to a folder" do
      dont_see_tag_in_folder(@tag_1, @folder_1)

      open_tags_section

      page.drag_and_drop_to_object "tag_#{@tag_1.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@tag_1, @folder_1)
    end

    it "copies a public tag to a folder" do
      dont_see_tag_in_folder(@public_tag, @folder_1)

      open_tags_section

      page.drag_and_drop_to_object "tag_#{@public_tag.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@public_tag, @folder_1)
    end

  end

  context "when dragging one and others are selected" do

    it "copies only dragged feed to a folder" do
      dont_see_feed_in_folder(@feed_1, @folder_1)

      open_feeds_section

      select_feed(@feed_2)

      page.drag_and_drop_to_object "feed_#{@feed_1.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_feed_in_folder(@feed_1, @folder_1)
      dont_see_feed_in_folder(@feed_2, @folder_1)
    end

    it "copies only the dragged private tag to a folder" do
      dont_see_tag_in_folder(@tag_1, @folder_1)

      open_tags_section

      select_tag(@tag_2)

      page.drag_and_drop_to_object "tag_#{@tag_1.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@tag_1, @folder_1)
      dont_see_tag_in_folder(@tag_2, @folder_1)
    end

    it "copies only the dragged public tag to a folder" do
      dont_see_tag_in_folder(@public_tag, @folder_1)

      open_tags_section

      select_tag(@tag_2)

      page.drag_and_drop_to_object "tag_#{@public_tag.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@public_tag, @folder_1)
      dont_see_tag_in_folder(@tag_2, @folder_1)
    end

  end

  context "when dragging many" do

    it "copies all selected feeds to a folder" do
      dont_see_feed_in_folder(@feed_1, @folder_1)
      dont_see_feed_in_folder(@feed_2, @folder_1)

      open_feeds_section

      select_feeds(@feed_1, @feed_2)

      page.drag_and_drop_to_object "feed_#{@feed_2.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_feed_in_folder(@feed_1, @folder_1)
      see_feed_in_folder(@feed_2, @folder_1)
    end

    it "copies all selected private tags to a folder" do
      dont_see_tag_in_folder(@tag_1, @folder_1)
      dont_see_tag_in_folder(@tag_2, @folder_1)

      open_tags_section

      select_tags(@tag_1, @tag_2)

      page.drag_and_drop_to_object "tag_#{@tag_2.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@tag_1, @folder_1)
      see_tag_in_folder(@tag_2, @folder_1)
    end

    it "copies all selected public tags to a folder" do
      dont_see_tag_in_folder(@tag_1, @folder_1)
      dont_see_tag_in_folder(@public_tag, @folder_1)

      open_tags_section

      select_tags(@tag_1, @public_tag)

      page.drag_and_drop_to_object "tag_#{@public_tag.id}", "folder_#{@folder_1.id}"
      page.wait_for :wait_for => :ajax

      see_tag_in_folder(@tag_1, @folder_1)
      see_tag_in_folder(@public_tag, @folder_1)
    end

  end
  
end

describe "dragging and dropping many feeds and tags between folders" do
  
  include FolderHelpers

  before(:each) do
    @current_user = Generate.user!
    @user = Generate.user!

    @folder_1 = Folder.create! :user => @current_user, :name => "Folder 1"
    @folder_2 = Folder.create! :user => @current_user, :name => "Folder 2"

    @feed_1 = Feed.create! :title => "Feed 1", :via => "http://example.com/atom", :uri => "urn:test:example1"
    FeedSubscription.create! :feed => @feed_1, :user => @current_user

    @feed_2 = Feed.create! :title => "Feed 2", :via => "http://another.example.com/atom", :uri => "urn:test:example2"
    FeedSubscription.create! :feed => @feed_2, :user => @current_user

    @tag_1 = Tag.create! :name => "tag 1", :user => @current_user

    @public_tag = Tag.create! :name => "public tag", :user => @user, :public => true
    TagSubscription.create! :tag => @public_tag, :user => @current_user
    
    @folder_1.feeds << @feed_1
    @folder_1.feeds << @feed_2
    @folder_1.tags << @tag_1
    @folder_1.tags << @public_tag

    login @current_user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
    page.window_maximize

    open_folders_section
  end

  it "copies the tags and feeds from one folder to another" do
    dont_see_feed_in_folder(@feed_1, @folder_2)
    dont_see_feed_in_folder(@feed_2, @folder_2)
    dont_see_tag_in_folder(@tag_1, @folder_2)
    dont_see_tag_in_folder(@public_tag, @folder_2)

    select_feeds_in_folder(@folder_1, @feed_1, @feed_2)
    select_tags_in_folder(@folder_1, @tag_1, @public_tag)
    
    page.drag_and_drop_to_object "css=#folder_#{@folder_1.id}_tag_items #tag_#{@public_tag.id}", "folder_#{@folder_2.id}"
    page.wait_for :wait_for => :ajax

    see_feed_in_folder(@feed_1, @folder_2)
    see_feed_in_folder(@feed_2, @folder_2)
    see_tag_in_folder(@tag_1, @folder_2)
    see_tag_in_folder(@public_tag, @folder_2)
  end

end
