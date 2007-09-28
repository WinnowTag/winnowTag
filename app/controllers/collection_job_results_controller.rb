# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  before_filter :login_required_unless_local
  before_filter :find_user
  
  # GET /collection_job_results
  # GET /collection_job_results.xml
  def index
    @collection_job_results = @user.collection_job_results

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @collection_job_results.to_xml }
    end
  end

  # GET /collection_job_results/1
  # GET /collection_job_results/1.xml
  def show
    @collection_job_result = @user.collection_job_results.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @collection_job_result.to_xml }
    end
  end  

  # POST /collection_job_results
  # POST /collection_job_results.xml
  def create
    if params[:collection_job_result]
      @collection_job_result = @user.collection_job_results.build(params[:collection_job_result])
    elsif job = params[:collection_job]      
      @collection_job_result = @user.collection_job_results.build(:message => job[:message], 
                                                                  :feed_id => job[:feed_id],
                                                                  :failed  => job[:failed])
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
