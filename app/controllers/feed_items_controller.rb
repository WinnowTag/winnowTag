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

        filters = { :order => params[:order], :direction => params[:direction],
                    :limit => limit, :offset => params[:offset],
                    :feed_ids => params[:feed_ids], :tag_ids => params[:tag_ids],
                    :text_filter => params[:text_filter],
                    :mode => params[:mode],
                    :user => current_user }
  
        @feed_items = FeedItem.find_with_filters(filters)    
        @feed_item_count = FeedItem.count_with_filters(filters)
      end
      format.atom do
        filters = { :limit => 20,
                    :order => params[:order], :direction => params[:direction],
                    :feed_ids => params[:feed_ids], :tag_ids => params[:tag_ids],
                    :text_filter => params[:text_filter],
                    :mode => params[:mode],
                    :user => current_user }
  
        @feed_items = FeedItem.find_with_filters(filters)
        
        feed = Atom::Feed.new do |feed|
          @feed_items.each do |feed_item|
            feed.entries << feed_item.to_atom
          end
        end
        render :xml => feed.to_xml
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
                  :mode => params[:mode],
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
  
  def sidebar
    render :layout => false
  end
  
private
  def update_access_time
    current_user.update_attribute(:last_accessed_at, Time.now.utc)
  end
end
