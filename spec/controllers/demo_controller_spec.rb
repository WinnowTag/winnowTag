require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DemoController do
  
  #Delete these examples and add some real ones
  it "should use DemoController" do
    controller.should be_an_instance_of(DemoController)
  end

  describe "GET 'index'" do
    before(:each) do
      @user = Generate.user
      User.should_receive(:demo_user).and_return(@user)
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
end
