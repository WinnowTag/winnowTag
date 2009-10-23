# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +FeedbacksController+ is used to provide users a way to submit feedback
# to the Winnow team. This controller is available to be used even if the user
# needs to update their password so they are able to request help during that
# process.
class FeedbacksController < ApplicationController
  permit "admin", :only => :index

  skip_before_filter :check_if_user_must_update_password, :only => [:new, :create]

  # The +index+ actions is restricted to admin users and is used to view the 
  # submitted feedback.
  # See FeedItemsController#index for an explanation of the html/json requests.
  def index
    respond_to do |format|
      format.html
      format.json do
        @feedbacks = Feedback.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction],
                                     :limit => limit, :offset => params[:offset])
        @full = @feedbacks.size < limit
      end
    end
  end
  
  def new
    @feedback = Feedback.new
    render :layout => false
  end
  
  def create
    current_user.feedbacks.create!(params[:feedback])
    render :nothing => true
  end
end
