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

describe ItemCache::FeedsController do
  before(:each) do
    @controller.stub!(:hmac_authenticated?).and_return(true)
  end
  
  describe "POST Atom::Entry to /item_cache/feeds" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Feed Title"
        e.id = "urn:peerworks.org:feed#222"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/222')
      end
      
      @feed = mock_model(Feed, :to_atom_entry => 'atom entry')
      Feed.stub!(:find_or_create_from_atom_entry).and_return(@feed)
    end
    
    it "should set the location header" do
      post 'create', :atom => @atom
      response.headers['Location'].should == item_cache_feed_url(@feed)
    end
    
    it "should have 201 as the status code" do
      post 'create', :atom => @atom
      response.code.should == "201"
    end
  end
  
  describe "POST Atom::Entry to /item_cache/feeds without valid credentials" do
    it "should return 401 Autentication Required" do
      @controller.should_receive(:hmac_authenticated?).and_return(false)
      post :create, :atom => @atom
      response.code.should == "401"
    end
  end
  
  describe "PUT Atom:Entry to /item_cache/feeds/1 without existing feed" do
    before(:each) do
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Feed Title"
        e.id = "urn:newtest"
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/222')
      end
    end
    
    it "should create the feed" do
      put :update, :id => @atom.id, :atom => @atom
      Feed.count.should == (@before_count + 1)
    end
    
    it "should return 200" do
      put :update, :id => @atom.id, :atom => @atom
      response.code.should == "200"
    end
    
    it "should create a feed with the same uri" do
      put :update, :id => @atom.id, :atom => @atom
      Feed.find_by_uri(@atom.id).should_not be_nil
    end
  end
  
  describe "PUT Atom::Entry to /item_cache/feeds/1" do
    before(:each) do
      @feed = Generate.feed!
      
      @before_count = Feed.count
      @atom = Atom::Entry.new do |e|
        e.title = "Feed Title"
        e.id = @feed.uri
        e.links << Atom::Link.new(:rel => 'self', :href => 'http://collector.org/222')
      end
    end
    
    it "should update the feed" do
      put :update, :id => @atom.id, :atom => @atom
      @feed.reload
      @feed.title.should == 'Feed Title'
    end
    
    it "should not add a new feed" do
      put :update, :id => @atom.id, :atom => @atom
      Feed.count.should == @before_count
    end
    
    it "should render 200" do
      put :update, :id => @atom.id, :atom => @atom
      response.code.should == "200"
    end
    
    describe "with a different id" do
      it "should not update the feed" do
        feed2 = Generate.feed!
        put :update, :id => feed2.uri, :atom => @atom
        feed2.reload
        feed2.title.should_not == 'Feed Title'
      end
      
      it "should return a 412 (Precondition Failed) error" do
        feed2 = Generate.feed!
        put :update, :id => feed2.uri, :atom => @atom
        response.code.should == "412"
      end
    end
  end
    
  describe "DELETE to /item_cache/feeds/1" do
    it "should delete the feed" do
      feed = mock_model(Feed)
      feed.should_receive(:destroy)
      Feed.should_receive(:find_by_uri).with("urn:uuid:blah").and_return(feed)
      delete :destroy, :id => "urn:uuid:blah"
    end    
  end
end
