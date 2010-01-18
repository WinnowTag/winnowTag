# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +FeedItemsController+ is used to manage the viewing of feed items.
class FeedItemsController < ApplicationController
  skip_before_filter :login_required, :only => :body
  
  # The +index+ action displays +FeedItem+s based on filters provided.
  # See also +FeedItem.find_with_filters+.
  def index
    respond_to do |format|
      # The html request is used to load the item browser shell only.
      # No actual feed items will be loaded here.
      format.html
      
      # The json request is used to load a page worth of items.
      format.json do
        # Each time a page of items is loaded, we log a +TagUsag+
        # for each +Tag+ that is being filtered on.
        params[:tag_ids].to_s.split(",").each do |tag_id|
          if tag = Tag.find_by_id(tag_id)
            TagUsage.create!(:tag => tag, :user => current_user)
          end
        end

        filters = { :limit => limit, :offset => params[:offset],
                    :feed_ids => params[:feed_ids], :tag_ids => params[:tag_ids],
                    :text_filter => params[:text_filter],
                    :mode => params[:mode],
                    :user => current_user }
  
        @feed_items = FeedItem.find_with_filters(filters)
        # The +@full+ flag is sent back to the client side javascript and
        # is used to determine if there are additional feed items to load.
        @full = @feed_items.size < limit
      end
      
      # the atom request is used to request a custom atom feed based on 
      # the filters to user requested.
      format.atom do
        # Each time an atom feed of items is loaded, we log a +TagUsag+
        # for each +Tag+ that is being filtered on.
        params[:tag_ids].to_s.split(",").each do |tag_id|
          TagUsage.create!(:tag_id => tag_id, :user_id => current_user.id)
        end

        filters = { :limit => 20,
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

  # The +mark_read+ action is used to mark feed items as read for the
  # logged in user. If an +id+ is provided, that individual feed item
  # is marked read, otherwise it the tag/feed/text/mode filters will 
  # be used to mark many feed items as read.
  def mark_read
    if params[:id]
      FeedItem.find(params[:id]).read_by!(current_user)
    else
      filters = { :feed_ids => params[:feed_ids],
                  :tag_ids => params[:tag_ids],
                  :text_filter => params[:text_filter],
                  :mode => params[:mode],
                  :user => current_user }
      FeedItem.read_by!(filters)
    end
    render :nothing => true
  end
  
  # The +mark_unread+ action is used to mark feed items as unread for the
  # logged in user. If an +id+ is provided, that individual feed item
  # is marked unread, otherwise it the tag/feed/text/mode filters will 
  # be used to mark many feed items as unread.
  def mark_unread
    if params[:id]
      FeedItem.find(params[:id]).unread_by!(current_user)
    else
      filters = { :feed_ids => params[:feed_ids],
                  :tag_ids => params[:tag_ids],
                  :text_filter => params[:text_filter],
                  :mode => params[:mode],
                  :user => current_user }
      FeedItem.unread_by!(filters)
    end
    render :nothing => true
  end
  
  # The +body+ action is used to load the main contents of a feed item.
  # This is lazy-loaded when the user opens a feed item to make the 
  # loading of the list of feed items faster.
  def body
    @feed_item = FeedItem.find(params[:id])
    render :layout => false
  end
  
  # The +moderation_panel+ action is used to load the tagging controls
  # for a feed item.
  # This is lazy-loaded when the user opens a tagging controls to make the 
  # loading of the list of feed items faster.
  def moderation_panel 
    @feed_item = FeedItem.find(params[:id]) 
    render :layout => false
  end
  
  # The +feed_information+ action is used to load the feed information
  # for a feed item.
  # This is lazy-loaded when the user opens the feed information panel
  # for feed item to make the loading of the list of feed items faster.
  def feed_information 
    @feed_item = FeedItem.find(params[:id]) 
    render :layout => false
  end

  # The +sidebar+ actions loads the contents of the feed items sidebar.
  def sidebar
    render :layout => false
  end
end
