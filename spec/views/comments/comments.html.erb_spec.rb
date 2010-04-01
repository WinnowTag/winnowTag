# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/comments/_comment.html.erb' do
  before(:each) do
    user = mock("user")
    user.should_receive(:has_role?).and_return(false)
    template.stub!(:current_user).and_return(user)
  end
  
  it "should not crash when the comment user is nil" do
    comment = mock_model(Comment, 
                :user => nil, 
                :updated_at => Time.now, 
                :tag => mock_model(Tag, :user => mock_model(User)),
                :body => "No comment")
    lambda { render :partial => '/comments/comment.html.erb', :locals => { :comment => comment } }.should_not raise_error
  end
end
