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

describe "keyboard shortcuts" do
  before(:each) do
    @feed_item2 = Generate.feed_item! :updated => 1.minute.ago
    @feed_item1 = Generate.feed_item! :updated => 0.minutes.ago
    
    login Generate.user!
    page.open feed_items_path
    page.wait_for :wait_for => :ajax
  end

  it "change_item" do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "j"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "j"
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "k"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", " "
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"
  end
  
  it "mark_read_unread" do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item1.id}.read"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.read"

    page.key_press "css=body", "n"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item1.id}.read"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.read"

    page.key_press "css=body", "m"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    see_element "#feed_item_#{@feed_item1.id}.read"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.read"

    page.key_press "css=body", "m"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item1.id}.read"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.read"
  end
  
  it "open_close_moderation_panel " do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .moderation_panel"
 
    page.key_press "css=body", "n" 
    see_element "#feed_item_#{@feed_item1.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .moderation_panel"
 
    page.key_press "css=body", "t" 
    see_element "#feed_item_#{@feed_item1.id}.selected" 
    assert_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .moderation_panel"
 
    page.key_press "css=body", "t" 
    see_element "#feed_item_#{@feed_item1.id}.selected" 
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .moderation_panel"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .moderation_panel"
  end
  
  it "open_close_item" do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "n"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "o"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "o"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"
  end
  
  it "closes open items when opening an item" do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "n"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "o"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "n"
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item1.id} .body"
    see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item2.id} .body"

    page.key_press "css=body", "o"
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    assert_not_visible "css=#feed_item_#{@feed_item1.id} .body"
    see_element "#feed_item_#{@feed_item2.id}.selected"
    assert_visible "css=#feed_item_#{@feed_item2.id} .body"
  end
  
  it "select_item" do
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"

    page.key_press "css=body", "n"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"

    page.key_press "css=body", "n"
    dont_see_element "#feed_item_#{@feed_item1.id}.selected"
    see_element "#feed_item_#{@feed_item2.id}.selected"

    page.key_press "css=body", "p"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"

    page.key_press "css=body", "p"
    see_element "#feed_item_#{@feed_item1.id}.selected"
    dont_see_element "#feed_item_#{@feed_item2.id}.selected"
  end
end
