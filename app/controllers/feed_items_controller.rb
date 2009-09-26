# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedItemsController < ApplicationController

  # The +index+ action displays +FeedItem+s based on the passed in filters.
  #
  # See also +FeedItem.find_with_filters+.
  def index
    respond_to do |format|
      format.html
      format.json do
        params[:tag_ids].to_s.split(",").each do |tag_id|
          if tag = Tag.find_by_id(tag_id)
            TagUsage.create!(:tag => tag, :user => current_user)
          end
        end

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
