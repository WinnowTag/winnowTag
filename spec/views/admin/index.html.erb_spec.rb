# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/admin/index' do
  before(:each) do
    login_as Generate.user!
  end
  
  def render_it
    render '/admin/index'
  end
  
  it "renders link to user management page" do
    render_it
    response.should have_tag("a[href=?]", users_path)
  end
  
  it "renders link to invites page" do
    render_it
    response.should have_tag("a[href=?]", invites_path)
  end
  
  it "renders link to messages page" do
    render_it
    response.should have_tag("a[href=?]", messages_path)
  end  
end
