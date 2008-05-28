# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  before_filter :login_required_unless_local
  before_filter :find_user
  
  def index
    @collection_job_results = @user.collection_job_results

    respond_to do |format|
      format.xml  { render :xml => @collection_job_results.to_xml }
    end
  end

  def show
    @collection_job_result = @user.collection_job_results.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @collection_job_result.to_xml }
    end
  end  

  def create
    @collection_job_result = @user.collection_job_results.build(
                                      :message => params[:collection_job_result][:message],
                                      :failed  => params[:collection_job_result][:failed],
                                      :feed_id => params[:collection_job_result][:feed_id])
    
    if (feed = @collection_job_result.feed) && !feed.duplicate.nil?
      @user.update_feed_state(feed)
    end
    
    if @collection_job_result.failed?
      @user.messages.create!(:body => _(:collection_failed, @collection_job_result.feed_title, @collection_job_result.message))
    else
      @user.messages.create!(:body => _(:collection_finished, @collection_job_result.feed_title))
    end
    
    respond_to do |format|
      if @collection_job_result.save
        format.xml  { head :created, :location => collection_job_result_url(@user, @collection_job_result) }
      else
        format.xml  { render :xml => @collection_job_result.errors.to_xml, :status => 422 }
      end
    end
  end
  
private
  def find_user
    unless @user = User.find_by_login(params[:user_id])
      @user = User.find(params[:user_id]) 
    end
  end
end
