# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedbacksController do
  describe "handling GET /feedbacks" do
    before(:each) do
      @current_user = Generate.admin!
      login_as @current_user
    end
  
    def do_get(params = {})
      get :index, params
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    describe "ajax request" do
      before(:each) do
        @feedback = mock_model(Feedback)
        Feedback.stub!(:search).and_return([@feedback])
      end
  
      it "should find all feedbacks" do
        Feedback.should_receive(:search).with({:text_filter => nil, :order => nil, :direction => nil, :limit => 40, :offset => nil}).and_return([@feedback])
        do_get(:format => "json")
      end
  
      it "should assign the found feedbacks for the view" do
        do_get(:format => "json")
        assigns[:feedbacks].should == [@feedback]
      end
      
      it "should assign the full to true when not enough items were found" do
        do_get(:format => "json", :limit => 5)
        assigns[:full].should be_true
      end
      
      it "should assign the full to false when enough items were found" do
        do_get(:format => "json", :limit => 1)
        assigns[:full].should be_false
      end
    end
  end

  describe "handling GET /feedbacks/new" do
    before(:each) do
      @current_user = Generate.user!
      login_as @current_user
    end

    before(:each) do
      @feedback = mock_model(Feedback)
      Feedback.stub!(:new).and_return(@feedback)
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new feedback" do
      Feedback.should_receive(:new).and_return(@feedback)
      do_get
    end
  
    it "should not save the new feedback" do
      @feedback.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new feedback for the view" do
      do_get
      assigns[:feedback].should equal(@feedback)
    end
  end

  describe "handling POST /feedbacks" do
    before(:each) do
      @current_user = Generate.user!
      login_as @current_user
    end
  
    before(:each) do
      @feedback = mock_model(Feedback, :to_param => "1")
      @feedbacks = stub("feedbacks", :create! => @feedback)
      current_user.stub!(:feedbacks).and_return(@feedbacks)
    end
    
    def do_post
      post :create, :feedback => {}
    end

    it "should create a new feedback" do
      @feedbacks.should_receive(:create!).with({}).and_return(@feedback)
      do_post
    end
  end
end