# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  with_auth_hmac HMAC_CREDENTIALS['collector']
  
  def create
    user = User.find_by_login(params[:user_id]) || User.find(params[:user_id])
    feed = Feed.find_by_id(params[:collection_job_result][:feed_id]) || Remote::Feed.find(params[:collection_job_result][:feed_id])
    
    if feed and feed.duplicate
      user.update_feed_state(feed)
    end
    
    if params[:collection_job_result][:failed].to_s =~ /true/i
      user.messages.create!(:body => t(:collection_failed, :title => feed.title, :message => params[:collection_job_result][:message]))
    end
    
    render :nothing => true, :status => :created
  end
end