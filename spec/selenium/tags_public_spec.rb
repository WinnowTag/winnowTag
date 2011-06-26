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
    page.click "subscribe_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 
  
    see_element "#tag_#{@tag.id}.subscribed"
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.subscribed"
    page.click "unsubscribe_tag_#{@tag.id}"

    page.wait_for :wait_for => :ajax

    dont_see_element "#tag_#{@tag.id}.subscribed"
  end
  
  it "globally excludes a public tag" do
    dont_see_element "#tag_#{@tag.id}.globally_excluded"
    page.click "globally_exclude_tag_#{@tag.id}"
    
    page.wait_for :wait_for => :ajax 

    see_element "#tag_#{@tag.id}.globally_excluded"
    
    page.refresh
    page.wait_for :wait_for => :page
    page.wait_for :wait_for => :ajax
    
    see_element "#tag_#{@tag.id}.globally_excluded"
    page.click "unglobally_exclude_tag_#{@tag.id}"

    page.wait_for :wait_for => :ajax

    dont_see_element "#tag_#{@tag.id}.globally_excluded"
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
