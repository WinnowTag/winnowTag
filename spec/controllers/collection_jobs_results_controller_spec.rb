# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJobResultsController do
  before(:each) do
    login_as(1)
    mock_user_for_controller
    User.stub!(:find).with(@user.id.to_s).and_return(@user)
  end
  
  it "should get index" do
    results = mock('results', :to_xml => "XML")
    @user.should_receive(:collection_job_results).and_return(results)
    
    get :index, :user_id => @user.id
    response.should be_success
    assigns[:collection_job_results].should == results
  end

  it "should create collection job result" do
    result = mock_model(CollectionJobResult)
    results = mock('collection_job_results')
    @user.should_receive(:collection_job_results).and_return(results)
    results.should_receive(:build).with({:message => "msg", :failed => 0, :feed_id => nil }).and_return(result)
    result.should_receive(:save).and_return(true)
    result.stub!(:feed).and_return(mock_model(Feed, :duplicate => nil))
    
    post :create, :collection_job_result => {:message => "msg", :failed => 0 }, :user_id => @user.id
    
    response.code.should == "201"
    response.headers['Location'].should == collection_job_result_url(@user, result)
  end
  
  it "can create without login from local" do
    login_as(nil)
    @controller.stub!(:local_request?).and_return(true)
    
    result = mock_model(CollectionJobResult)
    results = mock('collection_job_results')
    @user.should_receive(:collection_job_results).and_return(results)
    results.should_receive(:build).with({:message => "msg", :failed => 0, :feed_id => nil }).and_return(result)
    result.should_receive(:save).and_return(true)
    result.stub!(:feed)
    
    post :create, :collection_job_result => {:message => "msg", :failed => 0 }, :user_id => @user.id
  end
  
  it "should update user's feed state if the feed is a duplicate" do
    feed = mock_model(Feed, :duplicate => mock('dup'))
        
    result = mock_model(CollectionJobResult)
    results = mock('collection_job_results')
    @user.should_receive(:collection_job_results).and_return(results)
    results.should_receive(:build).with({:message => "msg", :failed => 0, :feed_id => 1 }).and_return(result)
    result.should_receive(:save).and_return(true)
    result.should_receive(:feed).and_return(feed)
    @user.should_receive(:update_feed_state).with(feed)
    
    post :create, :collection_job_result => {:message => "msg", :failed => 0, :feed_id => 1 }, :user_id => @user.id
  end  
end