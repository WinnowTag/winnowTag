# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


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
          render :status => :created, 
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
            if item = FeedItem.find_by_uri(params[:id])
              item.update_from_atom(params[:atom])
              render :nothing => true
            else
              render :status => :accepted, :nothing => true
            end
            
          rescue ArgumentError
            render :status => :precondition_failed, :nothing => true
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
