# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require File.dirname(__FILE__) + '/../spec_helper'

describe InvitesController do
  before(:each) do
    login_as Generate.admin!
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
