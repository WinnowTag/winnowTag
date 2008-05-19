# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsHelper do
  attr_reader :current_user
  
  before(:each) do
    @current_user = mock_model(User, valid_user_attributes)
  end
  
  describe "#can_edit_comment?" do
    
    def is_admin?
      @is_admin
    end
    
    before(:each) do
      @tag = mock_model(Tag, :user => nil)
      @comment = mock_model(Comment, :user => nil, :tag => @tag)
    end
    
    it "returns true for admins" do
      @is_admin = true
      can_edit_comment?(@comment).should be_true
    end
    
    it "returns true for tag owner" do
      @tag.stub!(:user).and_return(current_user)
      can_edit_comment?(@comment).should be_true
    end
    
    it "returns true for comment owner" do
      @comment.stub!(:user).and_return(current_user)
      can_edit_comment?(@comment).should be_true
    end
    
    it "returns false for everything else" do
      can_edit_comment?(@comment).should be_false
    end
  end
end