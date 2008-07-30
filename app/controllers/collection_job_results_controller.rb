# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  before_filter :login_required_unless_local
  
  def create
    user = User.find_by_login(params[:user_id]) || User.find(params[:user_id])
    message = params[:collection_job_result][:message]
    failed = params[:collection_job_result][:failed] =~ /true/i
    feed = Feed.find_by_id(params[:collection_job_result][:feed_id]) || Remote::Feed.find(params[:collection_job_result][:feed_id])
    
    if feed and feed.duplicate
      user.update_feed_state(feed)
    end
    
    # TODO: sanitize
    if failed
      user.messages.create!(:body => _(:collection_failed, feed.title, message))
    else
      user.messages.create!(:body => _(:collection_finished, feed.title))
    end
    
    render :nothing => true, :status => :created
  end
end