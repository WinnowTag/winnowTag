# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Handles recording collection job results from the collector for
# collection jobs initiated manually by the user.
class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  with_auth_hmac HMAC_CREDENTIALS['collector']
  
  # Creates a collection job result for the user.
  def create
    user = User.find_by_login(params[:user_id]) || User.find(params[:user_id])
    feed = Feed.find_by_id(params[:collection_job_result][:feed_id]) || Remote::Feed.find(params[:collection_job_result][:feed_id])
    
    if params[:collection_job_result][:failed].to_s =~ /true/i
      user.messages.create!(:body => t("winnow.notifications.collection_failed", :title => feed.title, :message => params[:collection_job_result][:message]))
    end
    
    render :nothing => true, :status => :created
  end
end