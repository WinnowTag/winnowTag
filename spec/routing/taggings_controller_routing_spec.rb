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

describe TaggingsController do
  describe "route generation" do
    it "should map { :controller => 'taggings', :action => 'create' } to /taggings" do
      route_for(:controller => "taggings", :action => "create").should == { :path => "/taggings", :method => :post }
    end

    it "should map { :controller => 'taggings', :action => 'destroy' } to /taggings" do
      route_for(:controller => "taggings", :action => "destroy").should == { :path => "/taggings", :method => :delete }
    end
  end

  describe "route recognition" do
    it "should generate params { :controller => 'taggings', action => 'create' } from POST /taggings" do
      params_from(:post, "/taggings").should == { :controller => "taggings", :action => "create" }
    end

    it "should generate params { :controller => 'taggings', action => 'destroy' } from DELETE /taggings" do
      params_from(:delete, "/taggings").should == { :controller => "taggings", :action => "destroy" }
    end
  end
end