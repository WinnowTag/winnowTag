# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CommentsController < ApplicationController
  before_filter :find_comment, :only => [:edit, :update, :destroy]

  def create
    @comment = current_user.comments.new(params[:comment])
    if @comment.save
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
  
  def mark_read
    comments = Comment.find(params[:comment_ids])
    comments.each { |comment| comment.read_by!(current_user) }
    respond_to :js
  end

private
  def find_comment
    @comment = Comment.find_for_user(current_user, params[:id])
  end
end