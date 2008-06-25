# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/messages/index.html.erb' do
  before(:each) do
    assigns[:messages] = []
    
    template.stub_render(:partial => "header_controls")
  end
  
  def render_it
    render '/messages/index.html.erb'
  end
  
  it "shows the header controls" do
    template.expect_render(:partial => "header_controls").and_return("header controls")
    render_it
    response.capture(:header_controls).should match(/header controls/)
  end

  describe "with an empty result set" do
    it "shows an empty message" do
      render_it
      response.should have_tag(".empty")
    end
  end

  describe "with a non-empty result set" do
    before(:each) do
      @messages = [mock_model(Message), mock_model(Message)]
      assigns[:messages] = @messages
      
      template.stub_render :partial => @messages
    end
    
    it "does not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end
  
    it "shows each message" do
      template.expect_render :partial => @messages
      render_it
    end
  end
end
