# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'
require 'active_resource/http_mock'

describe Remote::Classifier do
  it "should load via REST" do
    ActiveResource::HttpMock.respond_to do |http|
      http.get "/classifier.xml", {}, {:version => "1.0", :svnversion => "2808"}.to_xml(:root => 'classifier')
    end
    
    @classifier_info = Remote::Classifier.get_info
    @classifier_info.version.should == "1.0"
    @classifier_info.svnversion.should == "2808"
  end
end
