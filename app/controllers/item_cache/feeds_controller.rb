# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ItemCache
  class FeedsController < ItemCacheController
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