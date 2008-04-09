# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/index.html.erb' do
  before(:each) do
    login_as stub("user")
    template.stub_render(:partial => "index_header_controls")

    @presenter = stub("presenter", :feeds => [].paginate)
    assigns[:presenter] = @presenter
  end
  
  def render_it
    render '/feeds/index.html.erb'
  end
  
  it "shows the header controls" do
    template.expect_render(:partial => "index_header_controls").and_return("header controls")
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
      @feeds = [mock_model(Feed), mock_model(Feed)].paginate
      @presenter.stub!(:feeds).and_return(@feeds)
      
      template.stub_render :partial => @feeds
    end
    
    it "does not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end
  
    it "shows each feed" do
      template.expect_render :partial => @feeds
      render_it
    end
  end
end
