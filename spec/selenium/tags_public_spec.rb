# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "TagsPublicTest" do
  fixtures :users
  
  before(:each) do
    Tag.delete_all
    user = User.create! valid_user_attributes
    @tag = Tag.create! :name => "foo", :public => true, :user_id => user.id
    
    login
    page.open public_tags_path
    page.wait_for :wait_for => :ajax
  end
  
  it "subscribes to a public tag" do    
    dont_see_element "#tag_#{@tag.id}.subscribed"
    assert !page.is_checked("subscribe_tag_#{@tag.id}")
    assert page.is_checked("neither_tag_#{@tag.id}")
    page.click "subscribe_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 
  
    see_element "#tag_#{@tag.id}.subscribed"
    assert page.is_checked("subscribe_tag_#{@tag.id}")
    assert !page.is_checked("neither_tag_#{@tag.id}")
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.subscribed"
    assert page.is_checked("subscribe_tag_#{@tag.id}")
    assert !page.is_checked("neither_tag_#{@tag.id}")
  end
  
  it "globally excludes a public tag" do
    dont_see_element "#tag_#{@tag.id}.globally_excluded"
    assert !page.is_checked("globally_exclude_tag_#{@tag.id}")
    assert page.is_checked("neither_tag_#{@tag.id}")
    page.click "globally_exclude_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 

    see_element "#tag_#{@tag.id}.globally_excluded"
    assert page.is_checked("globally_exclude_tag_#{@tag.id}")
    assert !page.is_checked("neither_tag_#{@tag.id}")
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.globally_excluded"
    assert page.is_checked("globally_exclude_tag_#{@tag.id}")
    assert !page.is_checked("neither_tag_#{@tag.id}")
  end
end
