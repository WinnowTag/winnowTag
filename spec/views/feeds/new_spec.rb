# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/new' do
  before(:each) do
    @feed = mock_new_model(Feed, valid_feed_attributes)
    @view = mock_model(View)
    assigns[:feed] = @feed
    assigns[:view] = @view
  end
  
  it "should show form" do
    render '/feeds/new'
    response.should have_tag("form[action='/feeds?view_id=#{@view.id}']")
  end
end