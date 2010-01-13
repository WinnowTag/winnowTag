# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'
    
describe "text filter" do    

  before(:each) do
    @user = Generate.user!

    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "sets the text filter" do
    page.location.should =~ /\#order=date&direction=desc&mode=all$/

    page.type "text_filter", "ruby"
    
    # Need to fire the submit event on the form directly
    # because Selenium seems to skip handlers attached using
    # $(element).observe when run under IE. Using fire event
    # ensures that event handlers get called.
    #
    page.fire_event("text_filter_form", "submit")

    page.location.should =~ /\#order=date&direction=desc&mode=all&text_filter=ruby$/
  end
  
  it "keeps mode and tag filters intact" do
    @tag = Generate.tag!
    
    page.open login_path
    page.open feed_items_path(:anchor => "mode=trained&tag_ids=#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=#{@tag.id}$/

    page.type "text_filter", "ruby"
    page.fire_event("text_filter_form", "submit")

    page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=#{@tag.id}&text_filter=ruby$/
  end
end
  
describe "tag filter" do
  before(:each) do
    @user = Generate.user!

    @tag = Generate.tag!(:user => @user)
    @sql = Generate.tag!(:user => @user)
    
    # TODO: determine if this is still needed now that all models are
    # set up before a page is opened.
    #
    # In IE there seems to be a synching problem,
    # sometimes loading the page happens 
    # without the @tag and @sql tags present, I don't know if
    # this is a case of the follow load being ignored
    # because the previous one was same or what, but putting
    # the sleep here always ensures that @other appears in 
    # the page.
    sleep(1)
    
    login @user

    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  it "sets the tag filter" do
    page.location.should =~ /\#order=date&direction=desc&mode=all$/

    page.click "css=#name_tag_#{@tag.id}"

    page.location.should =~ /\#order=date&direction=desc&mode=all&tag_ids=#{@tag.id}$/
  end
  
  it "resets feed/tag filters only" do
    page.open login_path
    page.open feed_items_path(:anchor => "mode=trained&text_filter=ruby&feed_ids=1&tag_ids=#{@tag.id}")
    page.wait_for :wait_for => :ajax

    page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=#{@tag.id}&feed_ids=1&text_filter=ruby$/

    page.click "css=#name_tag_#{@tag.id}"
    
    page.location.should =~ /\#order=date&direction=desc&mode=trained&tag_ids=#{@tag.id}&text_filter=ruby$/
  end
  
  it "turns off a tag filter" do
    page.open login_path
    page.open feed_items_path(:anchor => "tag_ids=#{@sql.id},#{@tag.id}")
    page.wait_for :wait_for => :ajax

    page.location.should =~ /\#order=date&direction=desc&mode=all&tag_ids=#{@sql.id}%2C#{@tag.id}$/

    page.click "css=#name_tag_#{@tag.id}"
    
    page.location.should =~ /\#order=date&direction=desc&mode=all&tag_ids=#{@tag.id}$/
  end
  
  it "sets tag filter for all selected tags" do
    page.location.should =~ /\#order=date&direction=desc&mode=all$/
    
    page.click "css=#name_tag_#{@tag.id}"
    multi_select_click "css=#name_tag_#{@sql.id}"
    
    page.location.should =~ /\#order=date&direction=desc&mode=all&tag_ids=#{@tag.id}%2C#{@sql.id}$/
  end
end
