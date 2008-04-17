# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/about' do
  before(:each) do
    @classifier_info = mock_model(Remote::Classifier)
    assigns[:classifier_info] = @classifier_info
  end
  
  it "should display svn version" do
    @classifier_info.should_receive(:version).once.and_return("1.0")
    @classifier_info.should_receive(:git_revision).once.and_return("2808")
    
    render "/about/index"
    
    response.should have_text(/1\.0/)
    response.should have_text(/2808/)
  end
  
  it "should display classifier error when classifier_info is nil" do
    assigns[:classifier_info] = nil    
    render "/about/index"
    response.should have_tag("p.classifier_error", "The classifer could not be contacted.")
  end
end