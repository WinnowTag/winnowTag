# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feedbacks/index.html.erb' do
  before(:each) do
    template.stub!(:render).with(:partial => "header_controls")
  end
  
  def render_it
    render '/feedbacks/index.html.erb'
  end
  
  it "shows the header controls" do
    template.should_receive(:render).with(:partial => "header_controls").and_return("header controls")
    render_it
    response.capture(:header_controls).should match(/header controls/)
  end
end
