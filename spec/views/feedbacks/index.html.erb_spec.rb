# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feedbacks/index.html.erb' do
  before(:each) do
    template.stub_render(:partial => "header_controls")
  end
  
  def render_it
    render '/feedbacks/index.html.erb'
  end
  
  it "shows the header controls" do
    template.expect_render(:partial => "header_controls").and_return("header controls")
    render_it
    response.capture(:header_controls).should match(/header controls/)
  end

  it "shows a container for the loading indicator in the footer" do
    render_it
    response.capture(:footer).should have_tag("#feedbacks_indicator")
  end

  it "shows a container for the feedbacks count in the footer" do
    render_it
    response.capture(:footer).should have_tag("#feedbacks_count")
  end
end
