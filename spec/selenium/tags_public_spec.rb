# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "TagsPublicTest" do
  before(:each) do
    @current_user = Generate.user!
    @tag = Generate.tag! :public => true
    
    login @current_user
    page.open public_tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "subscribes to a public tag" do    
    dont_see_element "#tag_#{@tag.id}.subscribed"
    assert !page.is_checked("subscribe_tag_#{@tag.id}")
    page.click "subscribe_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 
  
    see_element "#tag_#{@tag.id}.subscribed"
    assert page.is_checked("subscribe_tag_#{@tag.id}")
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.subscribed"
    assert page.is_checked("subscribe_tag_#{@tag.id}")
  end
  
  it "globally excludes a public tag" do
    dont_see_element "#tag_#{@tag.id}.globally_excluded"
    assert !page.is_checked("globally_exclude_tag_#{@tag.id}")
    page.click "globally_exclude_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 

    see_element "#tag_#{@tag.id}.globally_excluded"
    assert page.is_checked("globally_exclude_tag_#{@tag.id}")
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.globally_excluded"
    assert page.is_checked("globally_exclude_tag_#{@tag.id}")
  end

  it "viewing items tagged with a specific tag also subscribes the user to that tag" do
    @current_user.subscribed_tags.should_not include(@tag)

    page.click "css=.tag_#{@tag.id} a.tagged"
    
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax

    page.location.should =~ /^#{feed_items_url}#.*$/
    @current_user.subscribed_tags(:reload).should include(@tag)
  end

  it "viewing items trained with a specific tag also subscribes the user to that tag" do
    @current_user.subscribed_tags.should_not include(@tag)

    page.click "css=.tag_#{@tag.id} a.trained"
    
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax

    page.location.should =~ /^#{feed_items_url}#.*$/
    @current_user.subscribed_tags(:reload).should include(@tag)
  end
end

describe "renaming my own public tags" do
  
  before(:each) do
    @current_user = Generate.user!
    @tag = Generate.tag! :user => @current_user, :public => true
    
    login @current_user
    page.open public_tags_path
    page.wait_for :wait_for => :ajax
    
    @new_name = "#{@tag.name}-renamed"
  end
  
  def rename_tag
    page.click "name_tag_#{@tag.id}"
    
    see_element("#name_tag_#{@tag.id}-inplaceeditor")
    page.type "css=input.editor_field", @new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{@tag.id}"
  end
  
  it "changes the name of the tag" do
    rename_tag
    @tag.reload
    @tag.name.should == @new_name
  end
  
  it "updates the tag name for the bias slider" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .slider_control .name")
    text.should include(@new_name)
  end
  
  it "updates the tag name in the 'show items tagged with' link" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .tagged .name")
    text.should include(@new_name)
  end
  
  it "updates the tag name in the 'show items trainded with' link" do
    rename_tag
    text = page.get_text("css=#tag_#{@tag.id} .trained .name")
    text.should include(@new_name)
  end
  
end

describe "Renaming tags as an admin" do
  
  before(:each) do
    user = Generate.admin!
    @tag = Generate.tag! :user => user, :public => true
    
    @new_name = "#{@tag.name}-renamed"

    login user
    page.open public_tags_path
    page.wait_for :wait_for => :ajax
  end
  
  def rename_tag
    page.click "name_tag_#{@tag.id}"
    
    see_element("#name_tag_#{@tag.id}-inplaceeditor")
    page.type "css=input.editor_field", @new_name
    page.key_down "css=input.editor_field", '\13' # enter
    page.wait_for :wait_for => :ajax
    see_element "#name_tag_#{@tag.id}"
  end
  
  it "updates the name in the 'training feed' link" do
    rename_tag
    @tag.reload
    text = page.get_attribute("css=#tag_#{@tag.id} .controls .feed.training@href")
    text.should =~ /#{url_for(:controller => "tags", :action => "training", :user => @tag.user_login, :tag_name => @tag.name, :format => "atom", :only_path => true)}$/
  end
  
end
