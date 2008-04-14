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
  DEFAULT_LIMIT = 40
  MAX_LIMIT = 100
  FEED_NOT_FOUND = "We couldn't find this feed in any of our databases.  Maybe it has been deleted or " +
                   "never existed.  If you think this is an error, please contact us." unless defined?(FEED_NOT_FOUND)
  COLLECTOR_DOWN = "Sorry, we couldn't find the feed and the main feed database couldn't be contacted. " +
                   "We are aware of this problem and will fix it soon. Please try again later." unless defined?(COLLECTOR_DOWN)
  include CollectionJobResultsHelper
  include ActionView::Helpers::TextHelper
  verify :only => :show, :params => :id, :redirect_to => {:action => 'index'}
  before_filter :flash_collection_job_result
  
  def index
    respond_to do |format|
      format.html
      format.js do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)
        @feeds, @feeds_count = Feed.search(:text_filter => params[:text_filter], :excluder => current_user, 
                                           :order => params[:order], :limit => limit, :offset => params[:offset],
                                           :count => true)
      end
    end

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
                                      
      if @feed.updated_on.nil?
        flash[:notice] = current_user.messages.create!(:body => "Thanks for adding the feed from '#{@feed.url}'. We will fetch the " <<
          "items soon and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar.")
      else
        flash[:notice] = current_user.messages.create!(:body => "We already have the feed from '#{@feed.url}', however we will " <<
          "update it now and we'll let you know when it is done. The feed has also been added to your feeds folder in the sidebar.")
      end
      
      respond_to do |format|
        format.html { redirect_to feed_url(@feed) }
        format.js
      end
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
      flash[:notice] = current_user.messages.create!(:body => "Imported #{pluralize(@feeds.size, 'feed')} from your OPML file")
      redirect_to feeds_url
    end
  end
  
  # First we try and find the feed in the local item cache.
  # If that fails we try and fetch it from the collector.
  #
  # If both of those fail, report a nice error message.
  def show
    begin
      @feed = Feed.find(params[:id])
      
      if @feed.duplicate_id
        redirect_to :id => @feed.duplicate_id
      end
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
    
    conditions = ["LOWER(title) LIKE LOWER(?) OR LOWER(alternate) LIKE LOWER(?)"]
    values = ["%#{@q}%", "%#{@q}%"]
    
    feed_ids = current_user.subscribed_feeds.map(&:id)
    if !feed_ids.blank?
      conditions << "id NOT IN (?)"
      values << feed_ids
    end
    
    @feeds = Feed.find_without_duplicates(:all, :conditions => [conditions.join(" AND "), *values], :limit => 30)
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
        Folder.remove_feed(current_user, feed.id)
      end
    end
      
    if params[:subscribe] =~ /false/i
      render :update do |page|
        page.select(".#{dom_id(feed)}").invoke("remove")
      end
    else
      render :nothing => true
    end
  end
end
