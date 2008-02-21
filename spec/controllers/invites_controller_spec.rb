# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe InvitesController do
  fixtures :users
  before(:each) do
    login_as(:admin)
  end
  
  describe "#create" do
    it "should set @invite on invalid invite" do
      post :create
      assigns[:invite].should_not be_nil
    end
  end
end