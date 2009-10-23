# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

module ItemCache
  # Receives updates to the feeds from the collector.
  #
  # +Feed+ updates come in the form of atom entry documents 
  # as they only contain metadata about the feed, not the items
  # themselves.
  #
  class FeedsController < ItemCacheController
    # Create a feed from an atom document.
    def create
      respond_to do |wants|
        wants.atom do
          feed = Feed.find_or_create_from_atom_entry(params[:atom])
          render :nothing => true,
                 :status => :created,
                 :location => item_cache_feed_url(feed)
        end
      end
    end
    
    # Update a feed from an atom document.
    def update
      begin
        if feed = Feed.find_by_uri(params[:id])
          feed.update_from_atom(params[:atom])
        else
          Feed.find_or_create_from_atom_entry(params[:atom])
        end
        render :nothing => true
      rescue ArgumentError
        render :nothing => true,
               :status => "412"               
      end
    end
    
    # Destroy a feed.
    def destroy
      respond_to do |wants|
        wants.atom do
          Feed.find_by_uri(params[:id]).destroy
          render :nothing => true
        end
      end
    end
  end
end