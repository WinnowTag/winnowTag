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
  
  describe "#using" do
    it "cannot be accessed by a non admin user" do
      cannot_access(:quentin, :get, :using)
    end
    
    it "can be accessed by an admin user" do
      login_as(:admin)
      get :using
      response.should be_success
    end
    
    describe "GET" do
      it "sets the using winnow setting for the view" do
        login_as(:admin)
        
        using = mock_model(Setting)
        Setting.should_receive(:find_or_initialize_by_name).with("Using Winnow").and_return(using)

        get :using

        assigns[:using].should == using
      end
    end
    
    describe "POST" do
      before(:each) do
        login_as(:admin)
        @using = mock_model(Setting, :value= => nil, :save! => nil)
        Setting.stub!(:find_or_initialize_by_name).and_return(@using)
      end
      
      it "updates the settings value" do
        @using.should_receive(:value=).with("The new value")
        @using.should_receive(:save!)

        post :using, :value => "The new value"
      end
      
      it "redirects to the using winnow page" do
        post :using, :value => "The new value"
        response.should redirect_to(using_path)
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