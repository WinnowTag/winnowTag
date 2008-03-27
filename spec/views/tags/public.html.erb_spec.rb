# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/tags/public' do
  fixtures :users
  before(:each) do
    login_as(1)
  end
  
  def render_it
    render '/tags/public'
  end
  
  describe "non-empty result set" do
    before(:each) do
      @tags = [mock_model(Tag, :name => "name", :comment => "comment", :bias => 1, :last_used_by => Time.now,
                               :positive_count => 0, :negative_count => 0, :classifier_count => 0, :user_id => 1, 
                               :user => mock_model(User))]
      @tags.stub!(:page_count).and_return(1)
      assigns[:tags] = @tags
    end
    
    it "should not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end

    it "should show a list of tags" do
      render_it
      response.should have_tag(".tag")
    end
  end
  
  describe "empty result set" do
    before(:each) do
      @tags = []
      @tags.stub!(:page_count).and_return(0)
      assigns[:tags] = @tags
    end
    
    it "should show an empty message" do
      render_it
      response.should have_tag(".empty")
    end

    it "should not show a list of tags" do
      render_it
      response.should_not have_tag(".tag")
    end
  end
end