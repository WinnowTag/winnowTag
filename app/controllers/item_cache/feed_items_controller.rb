# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

module ItemCache
  
  # Receives updates to the feed items from the collector.
  #
  # Item updates come in the form of atom documents.
  #
  class FeedItemsController < ItemCacheController
    # Create an +FeedItem+ from an atom document.
    #
    # Items are associated with a +Feed+ using the
    # feed_id parameter.
    #
    def create
      respond_to do |wants|
        wants.atom do
          feed = Feed.find_by_uri(params[:feed_id])
          item = feed.feed_items.find_or_create_from_atom(params[:atom])
          render :status => 201, 
                 :nothing => true,
                 :location => item_cache_feed_item_url(:id => item.uri)
        end
      end
    end
    
    # Update an item from an atom document.
    def update
      respond_to do |wants|
        wants.atom do
          begin
            item = FeedItem.find_by_uri(params[:id])
            item.update_from_atom(params[:atom])
            render :nothing => true
          rescue ArgumentError
            render :status => 412, :nothing => true
          end
        end
      end
    end
    
    # Destroy an item
    def destroy
      FeedItem.find_by_uri(params[:id]).destroy
      render :nothing => true
    end
  end
end
