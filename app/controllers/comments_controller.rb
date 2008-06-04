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

private
  def find_comment
    @comment = Comment.find_for_user(current_user, params[:id])
  end
end