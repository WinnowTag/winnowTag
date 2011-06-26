# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsHelper do
  include CommentsHelper

  attr_reader :current_user
  
  before(:each) do
    @current_user = Generate.user!
  end
  
  describe "#can_edit_comment?" do
    
    # CommentsHelper relies upon this method, which is defined in ApplicationHelper,
    # into which CommentsHelper is included.
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