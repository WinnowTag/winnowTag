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
    
describe "text filter" do    

  before(:each) do
    @user = Generate.user!

    login @user
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  xit "sets the text filter" do
    page.location.should =~ /\#mode=all&tag_ids=0$/

    page.type "text_filter", "ruby"
    
    # Need to fire the submit event on the form directly
    # because Selenium seems to skip handlers attached using
    # $(element).observe when run under IE. Using fire event
    # ensures that event handlers get called.
    #
    page.fire_event("text_filter_form", "submit")

    page.location.should =~ /\#mode=all&tag_ids=0&text_filter=ruby$/
  end
  
  xit "keeps mode and tag filters intact" do
    @tag = Generate.tag!
    
    page.open login_path
    page.open feed_items_path(:anchor => "mode=trained&tag_ids=#{@tag.id}")
    page.wait_for :wait_for => :ajax
    page.location.should =~ /\#mode=trained&tag_ids=#{@tag.id}$/

    page.type "text_filter", "ruby"
    page.fire_event("text_filter_form", "submit")

    page.location.should =~ /\#mode=trained&tag_ids=#{@tag.id}&text_filter=ruby$/
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
    page.location.should =~ /\#mode=all&tag_ids=0$/

    page.click "css=#name_tag_#{@tag.id}"

    page.location.should =~ /\#mode=all&tag_ids=#{@tag.id}$/
  end
  
  it "resets feed/tag filters only" do
    page.open login_path
    page.open feed_items_path(:anchor => "mode=trained&text_filter=ruby&tag_ids=#{@tag.id}")
    page.wait_for :wait_for => :ajax

    page.location.should =~ /\#mode=trained&tag_ids=#{@tag.id}&text_filter=ruby$/

    page.click "css=#name_tag_#{@tag.id}"
    
    page.location.should =~ /\#mode=all&tag_ids=#{@tag.id}&text_filter=ruby$/
  end
  
  it "turns off a tag filter" do
    page.open login_path
    page.open feed_items_path(:anchor => "tag_ids=#{@sql.id},#{@tag.id}")
    page.wait_for :wait_for => :ajax

    page.location.should =~ /\#mode=all&tag_ids=#{@sql.id}%2C#{@tag.id}$/

    page.click "css=#name_tag_#{@tag.id}"
    
    page.location.should =~ /\#mode=all&tag_ids=#{@tag.id}$/
  end
end
