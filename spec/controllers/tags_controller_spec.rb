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
    mock_tags = mock('tags')
    mock_tags.stub!(:find_by_id).and_return(@tag)
    @user.stub!(:tags).and_return(mock_tags)
    User.stub!(:find_by_login).and_return(@user)
  end
  
  it "should update the tag's bias" do
    @tag.should_receive(:update_attribute).with(:bias, 1.2)
    put "update", :id => 1, :tag => {:bias => 1.2}
    response.should be_success
  end
  
  it "should return not modified for show if if_modified after as updated on and last classified" do
    time = Time.now.yesterday
    @tag.stub!(:updated_on).and_return(time)
    @tag.stub!(:last_classified_at).and_return(time)    
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.httpdate
    
    get "show", :id => 1, :user_id => 'quentin'
    response.code.should == '304'
  end
  
  it "should return 200 for show if if_modified_since older than updated on" do
    @tag.stub!(:updated_on).and_return(Time.now)
    @tag.stub!(:last_classified_at).and_return(Time.now.yesterday.yesterday)
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
    
    get "show", :id => 1, :user_id => 'quentin'
    response.should be_success
  end
  
  it "should return 200 for show if last modified older than last classified" do
    @tag.stub!(:last_classified_at).and_return(Time.now)
    @tag.stub!(:updated_on).and_return(Time.now.yesterday.yesterday)
    request.env['HTTP_IF_MODIFIED_SINCE'] = Time.now.yesterday.httpdate
    
    get "show", :id => 1, :user_id => 'quentin'
    response.should be_success
  end
end