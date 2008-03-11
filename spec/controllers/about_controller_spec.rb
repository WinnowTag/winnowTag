# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe AboutController do
  before(:each) do
    login_as(1)
    mock_user_for_controller
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
  
  it "sets the using winnow setting for the view" do
    using = mock_model(Setting)
    Setting.should_receive(:find_or_initialize_by_name).with("Using Winnow").and_return(using)

    get :using

    assigns[:using].should == using
  end
end
