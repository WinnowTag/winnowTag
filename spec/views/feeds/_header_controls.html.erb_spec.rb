# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/_header_controls.html.erb' do
  def render_it
    render :partial => '/feeds/header_controls.html.erb'
  end
  
  it "displays the search field" do
    render_it
    response.should have_tag("input#text_filter")
  end

  it "displays an add/import feed lnk" do
    render_it
    response.should have_tag("a .add")
  end
end
