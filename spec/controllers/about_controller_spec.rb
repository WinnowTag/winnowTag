# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AboutController do
  describe "old specs" do
    before(:each) do
      login_as Generate.user!
    end
  
    it "should fetch classifier info" do
      mock = mock_model(Remote::Classifier)
      Remote::Classifier.should_receive(:get_info).and_return(mock)
      get "index"
      response.should be_success
      assigns[:classifier_info].should == mock
    end
  
    it "should set handle exceptions on classifier" do
      Remote::Classifier.should_receive(:get_info).once.and_raise(StandardError)
      get "index"
      response.should be_success
      assigns[:classifier_info].should be_nil
    end
  end
  
  describe "info" do
    before(:each) do
      @user = Generate.user!
      login_as @user

      @info = mock_model(Setting)
      Setting.stub!(:find_or_initialize_by_name).and_return(@info)

      @message = mock_model(Message)
      @latest_scope = stub("latest scope", :pinned_or_since => [@message])
      @for_scope = stub("for scope", :latest => @latest_scope)
      Message.stub!(:for).and_return(@for_scope)
    end
    
    def do_get
      get :info
    end
    
    it "sets the winnow info setting for the view" do
      Setting.should_receive(:find_or_initialize_by_name).with("Info").and_return(@info)

      do_get
      assigns[:info].should == @info
    end
    
    it "sets the messages for the view" do
      Message.stub!(:info_cutoff).and_return(60.days.ago)
      Message.should_receive(:for).with(@user).and_return(@for_scope)
      @for_scope.should_receive(:latest).with(30).and_return(@latest_scope)
      @latest_scope.should_receive(:pinned_or_since).with(Message.info_cutoff).and_return([@message])
      
      do_get
      assigns[:messages].should == [@message]
    end
  end
  
end
