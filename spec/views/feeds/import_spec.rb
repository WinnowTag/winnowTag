# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/import' do
  it "should show a form for uploading an OPML file" do
    render '/feeds/import'
    response.should have_tag("form[method = 'post'][action = '/feeds/import'][enctype = 'multipart/form-data']", true, response.body) do
      have_tag("input[type = 'file'][name = 'opml']")
    end
  end
end