# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/about/info' do
  before(:each) do
    assigns[:messages] = @messages = []
    assigns[:info] = stub("info", :value => "foo")

    template.stub_render(:partial => "messages/sidebar", :locals => { :messages => @messages })
  end
  
  def render_it
    render "/about/info"
  end
  
  it "renders the info winnow content" do
    render_it
    response.should have_tag(".info", "foo")
  end
  
  it "render the list of messages" do
    template.expect_render(:partial => "messages/sidebar", :locals => { :messages => @messages })
    render_it
  end
end