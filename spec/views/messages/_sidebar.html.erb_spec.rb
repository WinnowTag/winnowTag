# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/_sidebar.html.erb" do  
  before(:each) do
    @messages = []
    template.stub!(:render).with(:partial => "messages/sidebar_message", :collection => @messages)
  end
  
  def render_it
    render :partial => "/messages/sidebar", :locals => { :messages => @messages }
  end
  
  it "renders an empty message when no messages exist" do
    render_it
    response.should have_tag(".empty", "You have no recent messages.")
  end
  
  it "renders the messages" do
    message1 = mock_model(Message, :body => "foo", :created_at => Time.now)
    message2 = mock_model(Message, :body => "bar", :created_at => Time.now)
    @messages = [message1, message2]
    
    template.should_receive(:render).with(:partial => "messages/sidebar_message", :collection => @messages)
    render_it
  end
end