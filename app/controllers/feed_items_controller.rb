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
  # <tt>tag_filter</tt>:: The id of a tag to filter on.
  # <tt>feed_filter</tt>:: The id of a feed to filter on.
  # <tt>only_tagger</tt>:: Defines which tagger is used for the tag_filter. Can be 'user', 'classifier', or nil, in which case both are used.
  # <tt>mode</tt>:: When set to 'tag_inspect' the tag inspect mode is turned on. Any other value resets the mode to normal.
  # <tt>limit</tt>:: The number of items to fetch. Default is 40, max is 100.
  # <tt>offset</tt>:: The offset within the items to fetch from.
  #
  # == Tag Inspect Mode
  #
  # When tag inspect mode is on <tt>:only_tagger</tt> is forced to 'user' and :include_negative => true is
  # added to the parameters to +FeedItem.find_with_filters+. This forces only items tagged by the user,
  # either negatively or positively, to be shown.
  #
  # See also +FeedItem.find_with_filters+.
  def index
    @view.update_filters(params)
    @view.save!

    limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)

    filters = { :view => @view,
                :order => 'feed_items.time DESC',
                :limit => limit,
                :offset => params[:offset],
                :only_tagger => params[:only_tagger]
              }
              
    if @view.tag_inspect_mode?
      filters[:only_tagger] = 'user'
      filters[:include_negative] = true
    end
  
    @feed_items = FeedItem.find_with_filters(filters)    
  
    # If the request is just to load some items via Ajax we don't need the count
    # unless request.xhr? and not(params[:incremental])
      @feed_item_count = FeedItem.count_with_filters(filters)
    # end
    
    respond_to do |wants|
      wants.html
      wants.js 
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
      filters = { :view => @view, :only_tagger => params[:only_tagger] }

      if @view.tag_inspect_mode?
        filters[:only_tagger] = 'user'
        filters[:include_negative] = true
      end
      
      FeedItem.mark_read(filters)
    end
    render :nothing => true
  end
  
  def mark_unread
    @feed_item = FeedItem.find(params[:id])
    current_user.unread_items.create(:feed_item => @feed_item)
    render :nothing => true
  end
  
  def description
    @feed_item = FeedItem.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end
  
  def info
    @feed_item = FeedItem.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end

private
  def update_access_time
    current_user.update_attribute(:last_accessed_at, Time.now.utc)
  end
end
