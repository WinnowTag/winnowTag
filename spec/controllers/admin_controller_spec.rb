# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AdminController do
  describe "#index" do
    it "cannot be accessed by a non admin user" do
      cannot_access(Generate.user!, :get, :index)
    end
    
    it "can be accessed by an admin user" do
      login_as Generate.admin!
      get :index
      response.should be_success
    end
  end
end