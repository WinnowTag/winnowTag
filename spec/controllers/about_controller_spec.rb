# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AboutController do
  describe "old specs" do
    before(:each) do
      login_as Generate.user!
    end
  
    it "should fetch classifier info" do
      mock = mock_model(Remote::Classifier)
      Remote::Classifier.should_receive(:get_info).and_return(mock)
      get "index"
      response.should be_success
      assigns[:classifier_info].should == mock
    end
  
    it "should set handle exceptions on classifier" do
      Remote::Classifier.should_receive(:get_info).once.and_raise(StandardError)
      get "index"
      response.should be_success
      assigns[:classifier_info].should be_nil
    end
  end  
end
