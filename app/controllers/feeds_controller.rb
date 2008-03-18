# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# This controller doesn't create feeds directly. Instead it forwards
# feed creation requests on to the collector using Remote::Feed.
#
class FeedsController < ApplicationController
  FEED_NOT_FOUND = "We couldn't find this feed in any of our databases.  Maybe it has been deleted or " +
                   "never existed.  If you think this is an error, please contact us." unless defined?(FEED_NOT_FOUND)
  COLLECTOR_DOWN = "Sorry, we couldn't find the feed and the main feed database couldn't be contacted. " +
                   "We are aware of this problem and will fix it soon. Please try again later." unless defined?(COLLECTOR_DOWN)
  include CollectionJobResultsHelper
  include ActionView::Helpers::TextHelper
  verify :only => :show, :params => :id, :redirect_to => {:action => 'index'}
  before_filter :flash_collection_job_result
  
  def index
    setup_sortable_columns
    @search_term = params[:search_term]
    @feeds = Feed.search :search_term => @search_term, :excluder => current_user, 
                         :page => params[:page], :order => sortable_order('feeds', :field => 'title',:sort_direction => :asc)
  end
  
  def new
    @feed = Remote::Feed.new((params[:feed] or {:url => nil}))
  end
  
  def create
    @feed = Remote::Feed.find_or_create_by_url(params[:feed][:url])
    if @feed.errors.empty?
      FeedSubscription.find_or_create_by_feed_id_and_user_id(@feed.id, current_user.id) rescue nil      
      @collection_job = @feed.collect(:created_by => current_user.login, 
                                      :callback_url => collection_job_results_url(current_user))
                                      
      if !@feed.respond_to?(:updated_on) || @feed.updated_on.nil?
        flash[:notice] = "Thanks for adding the feed from '#{@feed.url}'. " + 
                         "We will fetch the items soon and we'll let you know when it is done. " +
                         "The feed has also been added to your feeds folder in the sidebar."
      else
        flash[:notice] = "We already have the feed from '#{@feed.url}', " +
                         "however we will update it now and we'll let you know when it is done. " +
                         "The feed has also been added to your feeds folder in the sidebar."
      end
            
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
        FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
        feed.collect(:created_by   => current_user.login, 
                     :callback_url => collection_job_results_url(current_user))
      end
      flash[:notice] = "Imported #{pluralize(@feeds.size, 'feed')} from your OPML file"
      redirect_to feeds_url
    end
  end
  
  # First we try and find the feed in the local item cache.
  # If that fails we try and fetch it from the collector.
  #
  # If both of those fail, report a nice error message.
  #
  def show
    begin
      @feed = Feed.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      begin
        @feed = Remote::Feed.find(params[:id])
      rescue Errno::ECONNREFUSED
        flash[:error] = COLLECTOR_DOWN
        render :action => 'error', :status => '503'
      rescue ActiveResource::ResourceNotFound
        flash[:error] = FEED_NOT_FOUND
        render :action => 'error', :status => '404'
      rescue ActiveResource::Redirection => redirect
        if id = redirect.response['Location'][/\/([^\/]*?)(\.\w+)?$/, 1]
          redirect_to :id => id
        else
          raise ActiveRecord::RecordNotFound
        end
      end        
    end
  end  

  def auto_complete_for_feed_title
    @q = params[:feed][:title]
    
    conditions = ["LOWER(title) LIKE LOWER(?) OR LOWER(via) LIKE LOWER(?)"]
    values = ["%#{@q}%", "%#{@q}%"]
    
    feed_ids = current_user.subscribed_feeds.map(&:id)
    if !feed_ids.blank?
      conditions << "id NOT IN (?)"
      values << feed_ids
    end
    
    @feeds = Feed.find(:all, :conditions => [conditions.join(" AND "), *values], :limit => 30)
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
        current_user.feed_subscriptions.create(:feed_id => feed.id) rescue nil
      else
        FeedSubscription.delete_all :feed_id => feed.id, :user_id => current_user.id
        FeedExclusion.delete_all :feed_id => feed.id, :user_id => current_user.id
      end
    end
      
    if params[:remove] =~ /true/i
      render :update do |page|
        page[dom_id(feed)].remove
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
