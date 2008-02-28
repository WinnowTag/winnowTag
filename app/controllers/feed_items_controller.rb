# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class FeedItemsController < ApplicationController
  include FeedItemsHelper
  include ActionView::Helpers::TextHelper
  before_filter :login_required
  before_filter :update_access_time
  DEFAULT_LIMIT = 40
  MAX_LIMIT = 100
     
  # The Index action has two modes.  The normal mode which displays
  # positive user and classifier tagged items and the tag inspect mode
  # which display positive and negative user tagged items.  Normal is the
  # default, tag inspect mode is set by passing mode=tag_inspect on
  # the url. In tag_inspect mode the @tag_inspect_mode instance variable
  # is set to true for use in the views.
  #
  # == Supported Parameters
  #
  # === The parameters are passed through to +FeedItem.find_with_filters+.
  #
  # <tt>limit</tt>:: The number of items to fetch. Default is 40, max is 100.
  # <tt>offset</tt>:: The offset within the items to fetch from.
  #
  # See also +FeedItem.find_with_filters+.
  def index
    respond_to do |format|
      format.html
      format.js do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)

        # if params[:folder_id] =~ /tags/
        #   params[:tag_ids] = (current_user.tag_ids + current_user.subscribed_tag_ids - current_user.excluded_tag_ids).join(",")
        # elsif params[:folder_id] =~ /feeds/
        #   params[:feed_ids] = current_user.feed_ids.join(",")
        # elsif folder = Folder.find_by_id(params[:folder_id])
        #   params[:feed_ids] = folder.feed_ids.join(",")
        #   params[:tag_ids] = folder.tag_ids.join(",")
        # end

        filters = { :order => 'feed_items.updated DESC',
                    :limit => limit,
                    :offset => params[:offset],
                    :feed_ids => params[:feed_ids],
                    :tag_ids => params[:tag_ids],
                    :text_filter => params[:text_filter],
                    :manual_taggings => params[:manual_taggings],
                    :user => current_user }
  
        @feed_items = FeedItem.find_with_filters(filters)    
        @feed_item_count = FeedItem.count_with_filters(filters)
      end
    end
  end
  
  def show
    respond_to do |wants|
      @feed_item = FeedItem.find(params[:id])
      wants.html {inspect; render :action => 'inspect'}
    end    
  end
  
  def inspect
    @feed_item = FeedItem.find(params[:id])
    @user_tags_on_item = @feed_item.taggings.find_by_user(current_user).map(&:tag)
    
    options = current_user.classifier.classification_options.merge({:include_evidence => true})        
    @classifications = current_user.classifier.guess(@feed_item, options)    
  end
  
  def mark_read
    if params[:id]
      @feed_item_id = params[:id]
      FeedItem.mark_read_for(current_user.id, @feed_item_id)
    else
      filters = { :feed_ids => params[:feed_ids],
                  :tag_ids => params[:tag_ids],
                  :text_filter => params[:text_filter],
                  :manual_taggings => params[:manual_taggings],
                  :user => current_user }
      
      FeedItem.mark_read(filters)
    end
    render :nothing => true
  end
  
  def mark_unread
    @feed_item = FeedItem.find(params[:id])
    current_user.read_items.find(:all, :conditions => {:feed_item_id => @feed_item}).each {|ri| ri.destroy}
    render :nothing => true
  end
  
  def description
    @feed_item = FeedItem.find(params[:id])
    respond_to :js
  end
  
  def info
    @feed_item = FeedItem.find(params[:id])
    respond_to :js
  end

  def moderation_panel 
    @feed_item = FeedItem.find(params[:id]) 
    respond_to :js
  end
  
private
  def update_access_time
    current_user.update_attribute(:last_accessed_at, Time.now.utc)
  end
end
