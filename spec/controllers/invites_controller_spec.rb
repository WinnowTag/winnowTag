# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe InvitesController do
  fixtures :users, :roles, :roles_users

  before(:each) do
    login_as(:admin)
  end
  
  describe "#index" do
    def do_get(q = nil)
      get :index, :q => q
    end
    
    it "is a success" do
      do_get
      response.should be_success
    end
    
    it "renders the index template" do
      do_get
      response.should render_template("index")
    end
    
    it "sets @invites for the view" do
      do_get
      assigns[:invites].should_not be_nil
    end
    
    it "find invites based on the search criteria" do
      Invite.should_receive(:search).with(:q => "ruby", :per_page => 20, :page => nil, :order => "created_at ASC")
      do_get("ruby")
    end
  end
  
  describe "#new" do
    def do_get
      get :new
    end
    
    it "is a success" do
      do_get
      response.should be_success
    end
    
    it "renders the new template" do
      do_get
      response.should render_template("new")
    end
    
    it "sets @invite for the view" do
      do_get
      assigns[:invite].should_not be_nil
    end
  end
  
  describe "#edit" do
    before(:each) do
      @invite = mock_model(Invite)
      Invite.stub!(:find).with("1").and_return(@invite)
    end
    
    def do_get
      get :edit, :id => 1
    end
    
    it "is a success" do
      do_get
      response.should be_success
    end
    
    it "renders the edit template" do
      do_get
      response.should render_template("edit")
    end
    
    it "sets @invite for the view" do
      do_get
      assigns[:invite].should_not be_nil
    end
  end
  
  describe "#create" do
    before(:each) do
      @invite = mock_model(Invite, :save => true, :activate! => nil, :code => "XYZ")
      Invite.stub!(:new).and_return(@invite)
      UserNotifier.stub!(:deliver_invite_accepted)
    end
    
    def do_post(params = {})
      post :create, :invite => params
    end
    
    it "creates a new invite" do
      params = {"email" => "user@example.com"}
      Invite.should_receive(:new).with(params).and_return(@invite)
      do_post params
    end

    describe "success" do
      it "redirects to the invites page" do
        do_post
        response.should redirect_to(invites_path)
      end

      it "activates the invite" do
        @invite.should_receive(:activate!)
        controller.stub!(:activate?).and_return(true)
        do_post
      end

      it "sends an email to the invitee" do
        controller.stub!(:activate?).and_return(true)
        UserNotifier.should_receive(:deliver_invite_accepted).with(@invite, "http://test.host/account/login?invite=XYZ")
        do_post
      end
    end

    describe "failure" do
      before(:each) do
        @invite.stub!(:save).and_return(false)
      end
    
      it "should set @invite on invalid invite" do
        do_post
        assigns[:invite].should == @invite
      end
    
      it "renders the new form" do
        do_post
        response.should render_template("new")
      end
    end
  end
  
  describe "#update" do
    before(:each) do
      @invite = mock_model(Invite, :update_attributes => true, :activate! => nil, :code => "XYZ")
      Invite.stub!(:find).and_return(@invite)
      UserNotifier.stub!(:deliver_invite_accepted)
    end
    
    def do_put(params = {})
      put :update, :id => 1, :invite => params
    end
    
    it "creates a new invite" do
      params = {"email" => "user@example.com"}
      Invite.should_receive(:find).and_return(@invite)
      do_put params
    end

    describe "success" do
      it "redirects to the invites page" do
        do_put
        response.should redirect_to(invites_path)
      end

      it "activates the invite" do
        @invite.should_receive(:activate!)
        controller.stub!(:activate?).and_return(true)
        do_put
      end

      it "sends an email to the invitee" do
        controller.stub!(:activate?).and_return(true)
        UserNotifier.should_receive(:deliver_invite_accepted).with(@invite, "http://test.host/account/login?invite=XYZ")
        do_put
      end
    end

    describe "failure" do
      before(:each) do
        @invite.stub!(:update_attributes).and_return(false)
      end
    
      it "should set @invite on invalid invite" do
        do_put
        assigns[:invite].should == @invite
      end
    
      it "renders the new form" do
        do_put
        response.should render_template("edit")
      end
    end
  end
  
  describe "#destroy" do
    before(:each) do
      Invite.stub!(:destroy).with("1")
    end
    
    def do_delete
      delete :destroy, :id => 1
    end
    
    it "redirects to the invites page" do
      do_delete
      response.should redirect_to(invites_path)
    end
  end
  
  describe "#activate" do
    before(:each) do
      @invite = mock_model(Invite, :activate! => nil, :code => "XYZ")
      Invite.stub!(:find).with("1").and_return(@invite)
      UserNotifier.stub!(:deliver_invite_accepted)
    end
    
    def do_put
      put :activate, :id => 1
    end
    
    it "redirects to the invites page" do
      do_put
      response.should redirect_to(invites_path)
    end
    
    it "activates the invite" do
      @invite.should_receive(:activate!)
      do_put
    end

    it "sends an email to the invitee" do
      UserNotifier.should_receive(:deliver_invite_accepted).with(@invite, "http://test.host/account/login?invite=XYZ")
      do_put
    end
  end
end
