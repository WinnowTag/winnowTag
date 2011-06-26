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


# The +CommentsController+ is used to support the commenting on tags feature.
class CommentsController < ApplicationController
  before_filter :find_comment, :only => [:edit, :update, :destroy]

  def create
    @comment = current_user.comments.new(params[:comment])
    if @comment.save
      @comment.read_by!(current_user)
      respond_to :js
    else
      render :action => "error.js.rjs"
    end
  end
  
  def edit
    respond_to :js
  end
  
  def update
    if @comment.update_attributes(params[:comment])
      respond_to :js
    else
      render :action => "error.js.rjs"
    end
  end
  
  def destroy
    @comment.destroy
    respond_to :js
  end

private
  def find_comment
    @comment = Comment.find_for_user(current_user, params[:id])
  end
end