# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe WelcomeController do
  before(:each) do
    login_as(1)
    mock_user_for_controller
  end
  
  it "should allow get" do
    get :index
    response.should be_success
  end
end
