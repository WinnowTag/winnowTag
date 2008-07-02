# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/invites/index.html.erb' do
  before(:each) do
    template.stub_render(:partial => "header_controls")
  end
  
  def render_it
    render '/invites/index.html.erb'
  end
  
  it "shows the header controls" do
    template.expect_render(:partial => "header_controls").and_return("header controls")
    render_it
    response.capture(:header_controls).should match(/header controls/)
  end

  it "shows a container for the invites count in the footer" do
    render_it
    response.capture(:footer).should have_tag("#invites_count")
  end
end
