# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class FeedsController < ApplicationController
  include CollectionJobResultsHelper
  include ActionView::Helpers::TextHelper
  verify :only => :show, :params => :id, :redirect_to => {:action => 'index'}
  before_filter :flash_collection_job_result
  
  def all
    setup_sortable_columns
    @search_term = params[:search_term]
    @feeds = Feed.search :search_term => @search_term, :excluder => current_user, 
                         :page => params[:page], :order => sortable_order('feeds', :field => 'title',:sort_direction => :asc)
  end
  
  def new
    @feed = Feed.new(params[:feed])
  end
  
  def create
    @feed = Remote::Feed.find_or_create_by_url(params[:feed][:url])
    if @feed.errors.empty?
      FeedSubscription.find_or_create_by_feed_id_and_user_id(@feed, current_user)
      @collection_job = @feed.collect(:created_by => current_user.login, 
                                      :callback_url => collection_job_results_url(current_user))
      flash[:notice] = "Added feed from '#{@feed.url}'. " +
                       "Collection has been scheduled for this feed, " +
                       "we'll let you know when it's done."
      redirect_to feed_url(@feed)
    else
      flash[:error] = @feed.errors.on(:url)
      render :action => 'new'        
    end
  end
  
  def import
    if params[:opml]
      @feeds = Remote::Feed.import_opml(params[:opml].read)
      @feeds.each do |feed|
        FeedSubscription.find_or_create_by_feed_id_and_user_id(feed, current_user)
        feed.collect(:created_by   => current_user.login, 
                     :callback_url => collection_job_results_url(current_user))
      end
      flash[:notice] = "Imported #{pluralize(@feeds.size, 'feed')} from your OPML file"
      redirect_to feeds_url
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
    
    feed_ids = current_user.subscribed_feeds.map(&:id)
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
      current_user.feed_exclusions.create! :feed_id => @feed.id
    else
      FeedExclusion.delete_all :feed_id => @feed.id, :user_id => current_user.id
    end
    render :nothing => true
  end

  def subscribe
    if feed = Feed.find_by_id(params[:id])
      if params[:subscribe] =~ /true/i
        current_user.feed_subscriptions.create! :feed_id => feed.id
      else
        FeedSubscription.delete_all :feed_id => feed.id, :user_id => current_user.id
        FeedExclusion.delete_all :feed_id => feed.id, :user_id => current_user.id
      end
    end
      
    if params[:remove] =~ /true/i
      render :update do |page|
        page[feed.dom_id].remove
      end
    else
      render :nothing => true
    end
  end
  
private
  def setup_sortable_columns
    add_to_sortable_columns('feeds', :field => 'title')
    add_to_sortable_columns('feeds', :field => 'feed_items_count', :alias => 'item_count')
    add_to_sortable_columns('feeds', :field => 'updated_on')
    add_to_sortable_columns('feeds', :field => 'globally_exclude')
  end
end
