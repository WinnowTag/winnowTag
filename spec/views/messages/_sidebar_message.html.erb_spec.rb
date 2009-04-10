# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/_sidebar_message.html.erb" do    
  before(:each) do
    @time = Time.now
    @message = mock_model(Message, :body => "foo", :created_at => @time, :pinned? => false)

    template.stub!(:format_date).and_return("the date")
  end

  def render_it
    render :partial => "/messages/sidebar_message", :locals => { :sidebar_message => @message }
  end
  
  it "displays the message body" do
    render_it
    response.should have_tag(".body", "foo")
  end
  
  describe "unpinned message" do
    before :each do
      @message.stub!(:pinned?).and_return(false)
    end
    
    it "displays the message created time" do
      template.should_receive(:format_date).with(@time).and_return("the date")
      render_it
      response.should have_tag(".date", "the date")
    end
  end  
  
  describe "pinned message" do
    before :each do
      @message.stub!(:pinned?).and_return(true)
    end
    
    it "does not display the message created time" do
      render_it
      response.should_not have_tag(".date")
    end
  end  
end