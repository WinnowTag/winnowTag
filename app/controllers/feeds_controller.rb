# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# This controller doesn't create feeds directly. Instead it forwards
# feed creation requests on to the collector using Remote::Feed.
class FeedsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :reject_winnow_feeds, :only => :create
  
  def index
    respond_to do |format|
      format.html do
        @feed = Remote::Feed.new(params[:feed] || {})
      end
      format.json do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)
        @feeds = Feed.search(:text_filter => params[:text_filter], :excluder => current_user,
                             :order => params[:order], :direction => params[:direction], 
                             :limit => limit, :offset => params[:offset])
        @full = @feeds.size < limit
      end
    end
  end

  def create   
    @feed = Remote::Feed.find_or_create_by_url_and_created_by(params[:feed][:url], current_user.login)
    if @feed.errors.empty?
      FeedSubscription.find_or_create_by_feed_id_and_user_id(@feed.id, current_user.id) rescue nil      
      @collection_job = @feed.collect(:created_by => current_user.login, 
                                      :callback_url => collection_job_results_url(current_user))
      
      # TODO: sanitize
      flash[:notice] = if @feed.updated_on.nil?
         _(:feed_added, @feed.url)
      else
        _(:feed_existed, @feed.url)
      end
      
      respond_to do |format|
        format.html { redirect_to feeds_path }
        format.js
      end
    else
      flash[:error] = @feed.errors.on(:url)
      render :action => 'index'
    end
  end
  
  def import
    @feeds = Remote::Feed.import_opml(params[:opml].read)
    @feeds.each do |feed|
      FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
      feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url(current_user))
    end
    flash[:notice] = _(:feeds_imported, @feeds.size)
    redirect_to feeds_url
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
    respond_to :js
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
  
private
  def reject_winnow_feeds
    if URI.parse(params[:feed][:url]).host == request.host
      flash[:error] = "Winnow generated feeds cannot be added to Winnow."
      render :action => 'new'
    end
  rescue
  end
end
