# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module ItemCache
  class FeedsController < ApplicationController
    skip_before_filter :login_required
    before_filter :login_required_unless_local, :check_atom
    
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
        feed = Feed.find(params[:id])
        feed.update_from_atom(params[:atom])
        render :nothing => true
      rescue ArgumentError
        render :nothing => true,
               :status => "412"               
      end
    end
    
    def destroy
      respond_to do |wants|
        wants.atom do
          Feed.find(params[:id]).destroy
          render :nothing => true
        end
      end
    end
  end
end