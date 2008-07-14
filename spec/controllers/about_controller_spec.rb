# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AboutController do
  describe "old specs" do
    before(:each) do
      login_as(1)
      mock_user_for_controller
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
      @user = User.create! valid_user_attributes
      login_as @user

      @info = mock_model(Setting)
      Setting.stub!(:find_or_initialize_by_name).and_return(@info)

      @message = mock_model(Message)
      Message.stub!(:find_for_user_and_global).and_return([@message])
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
      Message.should_receive(:find_for_user_and_global).with(@user.id, :limit => 30, :order => "created_at DESC").and_return([@message])
      
      do_get
      assigns[:messages].should == [@message]
    end
  end
  
end
