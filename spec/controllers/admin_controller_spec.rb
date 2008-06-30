# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AdminController do
  fixtures :users, :roles, :roles_users

  describe "#index" do
    it "cannot be accessed by a non admin user" do
      cannot_access(:quentin, :get, :index)
    end
    
    it "can be accessed by an admin user" do
      login_as(:admin)
      get :index
      response.should be_success
    end
  end
  
  describe "#info" do
    it "cannot be accessed by a non admin user" do
      cannot_access(:quentin, :get, :info)
    end
    
    it "can be accessed by an admin user" do
      login_as(:admin)
      get :info
      response.should be_success
    end
    
    describe "GET" do
      it "sets the winnow info setting for the view" do
        login_as(:admin)
        
        info = mock_model(Setting)
        Setting.should_receive(:find_or_initialize_by_name).with("Info").and_return(info)

        get :info

        assigns[:info].should == info
      end
    end
    
    describe "POST" do
      before(:each) do
        login_as(:admin)
        @info = mock_model(Setting, :value= => nil, :save! => nil)
        Setting.stub!(:find_or_initialize_by_name).and_return(@info)
      end
      
      it "updates the settings value" do
        @info.should_receive(:value=).with("The new value")
        @info.should_receive(:save!)

        post :info, :value => "The new value"
      end
      
      it "redirects to the winnow info page" do
        post :info, :value => "The new value"
        response.should redirect_to(info_path)
      end
    end
  end
  
  describe "#help" do
    it "cannot be accessed by a non admin user" do
      cannot_access(:quentin, :get, :help)
    end
    
    it "can be accessed by an admin user" do
      login_as(:admin)
      get :help
      response.should be_success
    end
    
    describe "GET" do
      it "sets the help setting for the view" do
        login_as(:admin)
        
        help = mock_model(Setting)
        Setting.should_receive(:find_or_initialize_by_name).with("Help").and_return(help)

        get :help

        assigns[:help].should == help
      end
    end
    
    describe "POST" do
      before(:each) do
        login_as(:admin)
        @help = mock_model(Setting, :value= => nil, :save! => nil)
        Setting.stub!(:find_or_initialize_by_name).and_return(@help)
      end
      
      it "updates the settings value" do
        @help.should_receive(:value=).with("The new value")
        @help.should_receive(:save!)

        post :help, :value => "The new value"
      end
      
      it "redirects to the admin page" do
        post :help, :value => "The new value"
        response.should redirect_to(admin_path)
      end
    end
  end
end