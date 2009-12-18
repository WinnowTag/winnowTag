# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/demo/index" do
  before(:each) do
    render 'demo/index'
  end
  
  #Delete this example and add some real ones or delete this file
  xit "should tell you where to find the file" do
    response.should have_tag('p', %r[Find me in app/views/demo/index])
  end
end
