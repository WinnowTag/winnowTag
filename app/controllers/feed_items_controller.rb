# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedItemsController < ApplicationController
  include FeedItemsHelper
  helper :feeds
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
      format.json do
        params[:tag_ids].to_s.split(",").each do |tag_id|
          TagUsage.create!(:tag_id => tag_id, :user_id => current_user.id)
        end

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
        params[:tag_ids].to_s.split(",").each do |tag_id|
          TagUsage.create!(:tag_id => tag_id, :user_id => current_user.id)
        end

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
      FeedItem.find(params[:id]).read_by!(current_user)
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
    FeedItem.find(params[:id]).unread_by!(current_user)
    render :nothing => true
  end
  
  def body
    @feed_item = FeedItem.find(params[:id])
    render :layout => false
  end
  
  def moderation_panel 
    @feed_item = FeedItem.find(params[:id]) 
    render :layout => false
  end
  
  def feed_information 
    @feed_item = FeedItem.find(params[:id]) 
    render :layout => false
  end

  def sidebar
    render :layout => false
  end
end
