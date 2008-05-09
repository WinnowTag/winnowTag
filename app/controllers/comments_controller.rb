class CommentsController < ApplicationController
  def create
    @comment = current_user.comments.create!(params[:comment])
    respond_to :js
  end
end
