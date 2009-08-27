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

  xit "viewing items tagged with a specific tag also subscribes the user to that tag" do
    @current_user.subscribed_tags.should_not include(@tag)

    link_text = I18n.t("winnow.tags.main.items_tagged_with", :tag => h(@tag.name))
    page.click "link=#{link_text}"
    page.wait_for_page_to_load

    page.location.should =~ /^#{feed_items_url}#.*$/
    @current_user.subscribed_tags(:reload).should include(@tag)
  end

  xit "viewing items trained with a specific tag also subscribes the user to that tag" do
    @current_user.subscribed_tags.should_not include(@tag)

    link_text = I18n.t("winnow.tags.main.items_trained_with", :tag => h(@tag.name))
    page.click "link=#{link_text}"
    page.wait_for_page_to_load

    page.location.should =~ /^#{feed_items_url}#.*$/
    @current_user.subscribed_tags(:reload).should include(@tag)
  end
end
