class CommentsController < ApplicationController
  def create
    @comment = current_user.comments.create!(params[:comment])
    respond_to :js
  end
  
  def edit
    @comment = Comment.find(params[:id])
    respond_to :js
  end
  
  def update
    @comment = Comment.find(params[:id])
    @comment.update_attributes!(params[:comment])
    respond_to :js
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    respond_to :js
  end
end
