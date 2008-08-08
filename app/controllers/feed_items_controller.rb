# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedItemsController < ApplicationController
  include FeedItemsHelper
  include ActionView::Helpers::TextHelper
  before_filter :login_required
     
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
        @full = @feed_items.size < limit
      end
      format.atom do
        filters = { :limit => 20,
                    :order => params[:order], :direction => params[:direction],
                    :feed_ids => params[:feed_ids], :tag_ids => params[:tag_ids],
                    :text_filter => params[:text_filter],
                    :mode => params[:mode],
                    :user => current_user,
                    :base_uri => "http://#{request.host}:#{request.port}",
                    :self_link => url_for(params),
                    :alt_link => url_for(params.update(:format => nil)) }
  
        render :xml => FeedItem.atom_with_filters(filters).to_xml
      end
    end
  end

  def clues
    tries = params[:tries].to_i
    tag = Tag.find(params[:tag])
    tag_url = url_for(:controller => 'tags', :action => 'training', :tag_name => tag.name, :user => tag.user, :format => 'atom')
    @clues = Remote::ClassifierClues.find_by_item_id_and_tag_url(params[:id], tag_url)
    
    if @clues == :redirect && tries < 7
      redirect_to params.update(:tries => tries + 1)
    else
      render :layout => false
    end
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
    current_user.read_items.find(:all, :conditions => {:feed_item_id => @feed_item}).each { |ri| ri.destroy }
    render :nothing => true
  end
  
  def body
    @feed_item = FeedItem.find(params[:id])
  end
  
  def add_tag_form 
    @feed_item = FeedItem.find(params[:id]) 
  end
  
  def information
    @feed_item = FeedItem.find(params[:id]) 
    @tag = Tag.find(params[:tag_id]) 
    @taggings = @feed_item.taggings.select { |tagging| tagging.tag == @tag }
  end
  
  def sidebar
    render :layout => false
  end
end
