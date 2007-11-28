# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe TagsController do
  before(:each) do
    login_as(1)
    mock_user_for_controller
    @tag = mock_model(Tag)    
    @tags.stub!(:find_by_id).and_return(@tag)
  end
  
  it "should update the tag's bias" do
    @tag.should_receive(:update_attribute).with(:bias, 1.2)
    put "update", :id => 1, :tag => {:bias => 1.2}, :view_id => 1
    response.should be_success
  end  
end