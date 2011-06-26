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

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/layouts/_navbar.html.erb' do
  def render_it
    login_as Generate.user!
    
    render :partial => '/layouts/navbar.html.erb'
  end
  
  describe "tabbed navigation" do
    it "contains a link to the feed items page" do
      render_it
      response.should have_tag(".main a[href=?]", feed_items_path)
    end
    
    it "contains a link to the my tags page" do
      render_it
      response.should have_tag(".main a[href=?]", tags_path)
    end
    
    it "contains a link to the public tags page" do
      render_it
      response.should have_tag(".main a[href=?]", public_tags_path)
    end
    
    it "contains a link to the feeds page" do
      render_it
      response.should have_tag(".main a[href=?]", feeds_path)
    end

    it "only contains the admin tab for admins"
    it "only contains the help path if one exists"
  end
  
  describe "extra navigation" do
    it "contains a link to logout" do
      render_it
      response.should have_tag(".extra a[href=?]", logout_path)
    end
  end
end
