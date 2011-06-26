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

describe "Tag Context menu" do
  before(:each) do
    @user = Generate.user!
    @tag1 = Generate.tag! :user => @user, :bias => 0
    @tag2 = Generate.tag! :bias => 1, :public => true
    @user.tag_subscriptions.create!(:tag => @tag2)

    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end
  
  describe "menu" do
    it "should show the context menu when the button is clicked" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.is_visible("tag_context_menu").should be_true
    end
  
    it "should hide the shown context menu when the document is clicked" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.click("css=body")
      page.is_visible("tag_context_menu").should be_false
    end
  
    it "should hide the shown context menu when the button is clicked again" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.is_visible("tag_context_menu").should be_true
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.is_visible("tag_context_menu").should be_false
    end
  
    it "should open the context menu when the button is clicked on another tag" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.is_visible("tag_context_menu").should be_true
      page.click("css=#tag_#{@tag2.id} div.context_menu_button")
      page.is_visible("tag_context_menu").should be_true
    end
  end
  
  describe "menu contents" do
    it "should add the 'public' class to the context menu on a public tag" do
      page.click("css=#tag_#{@tag2.id} div.context_menu_button")
      page.is_visible("css=div#tag_context_menu").should be_true
    end
    
    it "should not add the 'public' class to the context menu on a public tag" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.is_visible("css=#tag_context_menu").should be_true
      page.is_element_present("css=#tag_context_menu.public").should be_false
    end
  end
  
  describe "destroy tag" do
    it "should delete a tag" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.click("delete_menu_item")
      page.should be_confirmation
      page.confirmation
      page.wait_for :wait_for => :ajax
      page.is_element_present("tag_#{@tag1.id}").should be_false
      lambda{ Tag.find(@tag1.id) }.should raise_error
    end
    
    it "should unsubscribe from a public tag" do
      page.click("css=#tag_#{@tag2.id} div.context_menu_button")
      page.click("delete_menu_item")
      page.should be_confirmation
      page.confirmation
      page.wait_for :wait_for => :ajax
      page.is_element_present("tag_#{@tag2.id}").should be_false
      lambda{ Tag.find(@tag2.id) }.should_not raise_error
    end
  end
  
  describe "renaming" do
    it "should rename owned tag" do
      page.click("css=#tag_#{@tag1.id} div.context_menu_button")
      page.answer_on_next_prompt("renamed tag")
      page.click("rename_menu_item")
      page.wait_for :wait_for => :ajax
      Tag.find(@tag1.id).name.should == "renamed tag"
    end
    
    it "should not show prompt for subscribed public tag" do
      page.click("css=#tag_#{@tag2.id} div.context_menu_button")
      page.click("rename_menu_item")
      Tag.find(@tag2.id).name.should == @tag2.name
    end
  end
end
