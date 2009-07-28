# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# This controller doesn't create feeds directly. Instead it forwards
# feed creation requests on to the collector using +Remote::Feed+.
class FeedsController < ApplicationController
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
    creation = FeedManager.create(current_user, params[:feed][:url], collection_job_results_url(current_user))

    creation.success do |feed, notice|
      respond_to do |format|
        format.html do
          flash[:notice] = notice
          redirect_to feeds_path
        end
        format.js { @feed = feed }
      end
    end

    creation.failed do |feed, error|
      @feed = feed
      flash.now[:error] = error
      render :action => 'index'
    end
  end

  def import
    @feeds = Remote::Feed.import_opml(params[:opml].read)
    @feeds.each do |feed|
      FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
      feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url(current_user))
    end
    flash[:notice] = t("winnow.notifications.feeds_imported", :count => @feeds.size)
    redirect_to feeds_url
  end

  def auto_complete_for_feed_title
    @q = params[:feed][:title]
    
    conditions = ["(LOWER(title) LIKE LOWER(?) OR LOWER(alternate) LIKE LOWER(?))"]
    values = ["%#{@q}%", "%#{@q}%"]
    
    feed_ids = current_user.subscribed_feeds.map(&:id)
    if !feed_ids.blank?
      conditions << "feeds.id NOT IN (?)"
      values << feed_ids
    end
    
    @feeds = Feed.non_duplicates.all(:conditions => [conditions.join(" AND "), *values], :order => "feeds.sort_title", :limit => 30)
    render :layout => false
  end
  
  def globally_exclude
    @feed = Feed.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      FeedExclusion.find_or_create_by_feed_id_and_user_id(@feed.id, current_user.id)
    else
      FeedExclusion.delete_all :feed_id => @feed.id, :user_id => current_user.id
    end
    respond_to :js
  end

  def subscribe
    if feed = Feed.find_by_id(params[:id])
      if params[:subscribe] =~ /true/i
        FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
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
