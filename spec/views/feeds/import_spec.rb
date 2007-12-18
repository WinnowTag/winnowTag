# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/import' do
  before(:each) do
    @view = mock_model(View, :feed_filters => mock_model(ViewFeedState, :includes? => false))
    assigns[:view] = @view
  end
  
  it "should show a form for uploading an OPML file" do
    render '/feeds/import'
    response.should have_tag("form[method = 'post'][action = '/feeds/import?view_id=#{@view.id}'][enctype = 'multipart/form-data']", true, response.body) do
      have_tag("input[type = 'file'][name = 'opml']")
    end
  end
end