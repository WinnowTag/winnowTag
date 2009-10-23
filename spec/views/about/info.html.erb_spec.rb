# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/about/info' do
  before(:each) do
    assigns[:messages] = @messages = []
    assigns[:info] = stub("info", :value => "foo")

    template.stub!(:render).with(:partial => "messages/sidebar", :locals => { :messages => @messages })
  end
  
  def render_it
    render "/about/info"
  end
  
  it "renders the info winnow content" do
    render_it
    response.should have_tag(".info", "foo")
  end
  
  it "render the list of messages" do
    template.should_receive(:render).with(:partial => "messages/sidebar", :locals => { :messages => @messages })
    render_it
  end
end