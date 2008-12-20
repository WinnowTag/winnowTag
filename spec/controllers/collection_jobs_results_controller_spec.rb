# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJobResultsController do
  before(:each) do
    @message = mock_model(Message)
    @messages = stub("messages", :create! => @message)

    @user = mock_model(User)
    @user.stub!(:messages).and_return(@messages)
    User.stub!(:find).and_return(@user)
    
    @feed = mock_model(Feed, :title => "Some Blog", :duplicate => nil)
    Feed.stub!(:find_by_id).with(@feed.id.to_s).and_return(@feed)
    
    @controller.stub!(:hmac_authenticated?).and_return(true)
  end
  
  def do_post(message = nil)
    post :create, :collection_job_result => { :message => message, :failed => !message.nil?, :feed_id => @feed.id.to_s }, :user_id => @user.id
  end

  it "is created" do
    do_post
    response.code.should == "201"
  end
  
  it "creates a failure messsage when unsuccessful" do
    @messages.should_receive(:create!).with(:body => I18n.t(:collection_failed, :title => "Some Blog", :message => "Couldn't contact server")).and_return(@message)  
    do_post("Couldn't contact server")
  end
  
  it "updates user's feed state if the feed is a duplicate" do
    @feed.stub!(:duplicate).and_return(mock_model(Feed))

    @user.should_receive(:update_feed_state).with(@feed)
    do_post
  end
  
  it "reponds with 401 if hmac is not authenticated" do
    @controller.should_receive(:hmac_authenticated?).and_return(false)
    do_post
    response.code.should == "401"
  end
end