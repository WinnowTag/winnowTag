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

describe FeedManager, '#create' do
  
  it "finds or creates the feed remotely" do
    @user = mock_model(User, :login => "jdoe")
    remote_feed = mock_model(Remote::Feed,
                             :valid? => false,
                             :errors => stub("errors", :full_messages => stub("full_messages", :to_sentence => "")))
    Remote::Feed.should_receive(:find_or_create_by_url_and_created_by).with("feed_url", "jdoe").and_return(remote_feed)
    FeedManager.create(@user, "feed_url", "collection_job_results_url")
  end
  
  context "when the remote feed is invalid" do
    
    it "indicates failure" do
      @user = mock_model(User, :login => "jdoe")
      remote_feed = mock_model(Remote::Feed,
                               :valid? => false,
                               :errors => stub("errors", :full_messages => stub("full_messages", :to_sentence => "")))
      multiblock = stub("multiblock")
      Remote::Feed.stub!(:find_or_create_by_url_and_created_by).and_return(remote_feed)
      Multiblock.should_receive(:[]).with(:failed, remote_feed, "").and_return(multiblock)
      FeedManager.create(@user, "feed_url", "collection_job_results_url").should == multiblock
    end
    
  end
  
  context "when the remote feed is valid" do
    
    before(:each) do
      @user = mock_model(User, :login => "jdoe")
      @remote_feed = mock_model(Remote::Feed, :valid? => true, :collect => nil, :uri => "foo", :url => "bar")
      @feed = mock_model(Feed, :via => "foo")
      
      Remote::Feed.stub!(:find_or_create_by_url_and_created_by).and_return(@remote_feed)
      Feed.stub!(:find_by_uri).and_return(@feed)
    end
    
    it "collects the remote feed" do
      @remote_feed.should_receive(:collect).with(:created_by => "jdoe", :callback_url => "collection_job_results_url")
      FeedManager.create(@user, "feed_url", "collection_job_results_url")
    end
    
    it "tries to find the feed" do
      Feed.should_receive(:find_by_uri).with(@remote_feed.uri).and_return(@feed)
      FeedManager.create(@user, "feed_url", "collection_job_results_url")
    end
    
    context "when the feed is found" do
      it "indicates success" do
        message = I18n.t("winnow.notifications.feed_existed", :url => h(@feed.via))
        Multiblock.should_receive(:[]).with(:success, @feed, message).and_return(@multiblock)
        FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
      end
    end
    
    context "when the feed is not found" do
      before(:each) do
        Feed.stub!(:find_by_uri).and_return(nil)
      end
      
      it "creates the feed" do
        Multiblock.stub!(:[]).and_return(@multiblock)
        Feed.should_receive(:create!).with(:uri => @remote_feed.uri, :via => @remote_feed.url).and_return(@feed)
        FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
      end
      
      it "indicates success" do
        Feed.stub!(:create!).and_return(@feed)
        message = I18n.t("winnow.notifications.feed_added", :url => h(@feed.via))
        Multiblock.should_receive(:[]).with(:success, @feed, message).and_return(@multiblock)
        FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
      end
    end
    
    context "when the feed is not found but is then created before winnow creates it" do
      before(:each) do 
        Feed.should_receive(:find_by_uri).and_return(nil, @feed)
        Feed.should_receive(:create!).and_raise(ActiveRecord::StatementInvalid.new)
      end
      
      it "should indicate success... eventually" do
        message = I18n.t("winnow.notifications.feed_added", :url => h(@feed.via))
        Multiblock.should_receive(:[]).with(:success, @feed, message).and_return(@multiblock)
        FeedManager.create(@user, "feed_url", "collection_job_results_url").should == @multiblock
      end
    end
  end
end
