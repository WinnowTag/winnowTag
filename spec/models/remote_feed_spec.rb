# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'
require 'active_resource/http_mock'

describe Remote::Feed do
  it "should send import_opml messages" do
    ActiveResource::HttpMock.respond_to do |http|
      http.post '/feeds/import_opml.xml', {}, [Feed.find(1)].to_xml, 200
    end
    
    feeds = Remote::Feed.import_opml(File.read(File.join(RAILS_ROOT, 'spec', 'fixtures', 'example.opml')))
    feeds.should == [Remote::Feed.new(Feed.find(1).attributes)]
  end
end