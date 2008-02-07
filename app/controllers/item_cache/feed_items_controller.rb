# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module ItemCache
  class FeedItemsController < ApplicationController
    skip_before_filter :login_required
    before_filter :login_required_unless_local, :check_atom
    
    def create
      respond_to do |wants|
        wants.atom do
          feed = Feed.find(params[:feed_id])
          item = feed.feed_items.find_or_create_from_atom(params[:atom])
          render :status => 201, 
                 :nothing => true,
                 :location => item_cache_feed_item_url(item)
        end
      end
    end
    
    def update
      respond_to do |wants|
        wants.atom do
          begin
            item = FeedItem.find(params[:id])
            item.update_from_atom(params[:atom])
            render :nothing => true
          rescue ArgumentError
            render :status => 412, :nothing => true
          end
        end
      end
    end
    
    def destroy
      FeedItem.find(params[:id]).destroy
      render :nothing => true
    end
  end
end
