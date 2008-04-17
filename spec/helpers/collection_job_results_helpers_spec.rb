# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionJobResultsHelper do
  attr_accessor :current_user, :flash
  before(:each) do
    @current_user = mock_model(User)
    @flash = {}
  end
  
  describe "flash_collection_job_result" do
    before(:each) do
      @result = mock_model(CollectionJobResult, :feed_id => 123, :failed? => false, :feed_title => 'Title')
      @result.stub!(:update_attribute)
      @current_user.stub!(:collection_job_result_to_display).and_return(@result)
      
      @message = mock_model(Message)
      @messages = stub("messages")
      @messages.should_receive(:create!).with(:body => 'We have finished fetching new items for Title').and_return(@message)
      @current_user.stub!(:messages).and_return(@messages)
    end
      
    it "show message for result" do
      flash_collection_job_result
      flash[:notice].should == @message
    end
  end
end