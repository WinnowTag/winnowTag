# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class FeedsController < ApplicationController
  include CollectionJobResultsHelper
  include ActionView::Helpers::TextHelper
  permit 'admin', :only => [:import, :update]  
  verify :only => :show, :params => :id, :redirect_to => {:action => 'index'}
  before_filter :flash_collection_job_result
  
  def index
    respond_to do |wants|
      wants.html do
        add_to_sortable_columns('feeds', :field => 'title')
        add_to_sortable_columns('feeds', :field => 'feed_items_count', :alias => 'item_count')
        add_to_sortable_columns('feeds', :field => 'updated_on')
        add_to_sortable_columns('feeds', :field => 'view_state')
        add_to_sortable_columns('feeds', :field => 'globally_exclude')

        @search_term = params[:search_term]
        @feeds = Feed.search :search_term => @search_term, :view => @view,
                             :page => params[:page], :order => sortable_order('feeds', :field => 'title',:sort_direction => :asc)
      end
      wants.xml { render :xml => Feed.find(:all).to_xml }
    end
  end
  
  def new
    @feed = Feed.new(params[:feed])
  end
  
  def create
    @feed = Remote::Feed.find_or_create_by_url(params[:feed][:url])
    if @feed.errors.empty?
      @collection_job = @feed.collect(:created_by => current_user.login, 
                                      :callback_url => collection_job_results_url(current_user))
      flash[:notice] = "Added feed from '#{@feed.url}'. " +
                       "Collection has been scheduled for this feed, " +
                       "we'll let you know when it's done."
      redirect_to feed_url(@feed, :view_id => @view.id)
    else
      flash[:error] = @feed.errors.on(:url)
      render :action => 'new'        
    end
  end
  
  def show
    @feed = Feed.find(params[:id])
    if @feed.duplicate
      redirect_to feed_url(@feed.duplicate)
    end
  end  

  def auto_complete_for_feed_title
    @q = params[:feed][:title]
    
    conditions = ["LOWER(title) LIKE LOWER(?)"]
    values = ["%#{@q}%"]
    
    feed_ids = @view.feed_filters.map(&:feed_id) + current_user.excluded_feeds.map(&:id)
    if !feed_ids.blank?
      conditions << "id NOT IN (?)"
      values << feed_ids
    end
    
    @feeds = Feed.find(:all, :conditions => [conditions.join(" AND "), *values])
    render :layout => false
  end
  
  def globally_exclude
    @feed = Feed.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      ExcludedFeed.create! :feed_id => @feed.id, :user_id => current_user.id
      ViewFeedState.delete_all_for(@feed, :only => current_user)
    else
      ExcludedFeed.delete_all :feed_id => @feed.id, :user_id => current_user.id
    end
  end
end
