# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +FeedsController+ is used to manage the viewing and creation of feeds.
class FeedsController < ApplicationController
  # See FeedItemsController#index for an explanation of the html/json requests.
  def index
    respond_to do |format|
      format.html do
        # A new feed is instantiated here so it can be used on 
        # the Add/Import feed form.
        @feed = Remote::Feed.new(params[:feed] || {})
      end
      format.json do
        @feeds = Feed.search(:text_filter => params[:text_filter], :excluder => current_user,
                             :order => params[:order], :direction => params[:direction], 
                             :limit => limit, :offset => params[:offset])
        @full = @feeds.size < limit
      end
    end
  end

  # The +create+ action is used when a user requests a feed url to be added
  # to winnow. See FeedManager#create for more details on this creation process.
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

  # The +import+ action is used to import an OPML file of feed urls.
  # This is done by communicateing with the Collector via the
  # +Remote::Feed+ model.
  # 
  # A collection request is sent to the Collector for each of the 
  # imported feeds.
  # 
  # A FeedSubscription is created for each Feed and the logged in user.
  def import
    @feeds = Remote::Feed.import_opml(params[:opml].read)
    @feeds.each do |feed|
      feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url(current_user))
    end
    flash[:notice] = t("winnow.notifications.feeds_imported", :count => @feeds.size)
    redirect_to feeds_url
  end
  
  # The +globally_exclude+ action is used to add/remove a feed from a users
  # list of feed exlucsions.
  def globally_exclude
    @feed = Feed.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      FeedExclusion.find_or_create_by_feed_id_and_user_id(@feed.id, current_user.id)
    else
      FeedExclusion.delete_all :feed_id => @feed.id, :user_id => current_user.id
    end
    respond_to :js
  end
end
