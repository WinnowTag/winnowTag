class CommentsController < ApplicationController
  def create
    current_user.comments.create!(params[:comment])
    redirect_to :back
  end
end
