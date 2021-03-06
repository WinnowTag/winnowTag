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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DemoController do
  
  #Delete these examples and add some real ones
  it "should use DemoController" do
    controller.should be_an_instance_of(DemoController)
  end

  describe "GET 'index'" do
    before(:each) do
      @user = Generate.user
      User.should_receive(:find_by_login).with("pw_demo").and_return(@user)
    end
    
    it "should set the user to the demo user" do
      get :index
      assigns[:user].should == @user
    end
    
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end
  
  describe "GET index.json" do
    before(:each) do
      @user = Generate.user
      User.should_receive(:find_by_login).with("pw_demo").and_return(@user)
    end
    
    it "should be successful" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json'
      response.should be_success
    end
    
    it "should pass offset through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => "40", :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :offset => "40"
      response.should be_success
    end
    
    it "should not pass limit through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :limit => "100"
      response.should be_success
    end
    
    it "should pass tag ids through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => "23").and_return([])
      get 'index', :format => 'json', :tag_ids => "23"
      response.should be_success  
    end
    
    it "should not pass feed ids through to find" do
      FeedItem.should_receive(:find_with_filters).with(:user => @user, :offset => nil, :limit => 80, :tag_ids => nil).and_return([])
      get 'index', :format => 'json', :feed_ids => "23"
      response.should be_success
    end
  end
end
