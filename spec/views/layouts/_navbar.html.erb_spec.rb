# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/layouts/_navbar.html.erb' do
  def render_it
    login_as Generate.user!
    
    render :partial => '/layouts/navbar.html.erb'
  end
  
  describe "tabbed navigation" do
    it "contains a link to the feed items page" do
      render_it
      response.should have_tag(".main a[href=?]", feed_items_path)
    end
    
    it "contains a link to the my tags page" do
      render_it
      response.should have_tag(".main a[href=?]", tags_path)
    end
    
    it "contains a link to the public tags page" do
      render_it
      response.should have_tag(".main a[href=?]", public_tags_path)
    end
    
    it "contains a link to the feeds page" do
      render_it
      response.should have_tag(".main a[href=?]", feeds_path)
    end

    it "only contains the admin tab for admins"
    it "only contains the help path if one exists"
  end
  
  describe "extra navigation" do
    it "contains a link to logout" do
      render_it
      response.should have_tag(".extra a[href=?]", logout_path)
    end
  end
end
