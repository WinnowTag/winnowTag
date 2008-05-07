class FeedbacksController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.js do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)
        @feedbacks = Feedback.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction],
                                     :limit => limit, :offset => params[:offset])
        @full = @feedbacks.size < limit
      end
    end
  end
  
  def new
    @feedback = Feedback.new
    respond_to :js
  end
  
  def create
    current_user.feedbacks.create!(params[:feedback])
    respond_to :js
  end
end
