# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/invites/_header_controls.html.erb' do
  def render_it
    render :partial => '/invites/header_controls.html.erb'
  end
  
  it "shows the create invite button" do
    render_it
    response.should have_tag("a[href=?]", new_invite_path)
  end
end
