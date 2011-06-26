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