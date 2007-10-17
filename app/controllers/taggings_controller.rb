# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class TaggingsController < ApplicationController
  helper :feed_items
  verify :method => :post, :render => SHOULD_BE_POST
  verify :params => :tagging, :render => MISSING_PARAMS
  
  # Creates a single tagging for a <Taggable, Tagger, Tag>
  def create
    respond_to do |wants|
      params[:tagging][:tag] = Tag(current_user, params[:tagging][:tag])
      @tagging = current_user.taggings.build(params[:tagging])
      @feed_item = @tagging.feed_item
      
      if @tagging.save    
        wants.js
      else
        wants.js   { render :update do |page| page.alert("Tagging failed") end }
      end
    end 
  end
  
  # Destroys taggings
  #
  #  Accepted Parameters:
  #    - tagging: 
  #         taggable_type/taggable_id: The type and id of a taggable to destroy a tagging on.
  #         tag: The name of the tag to destroy the tagging on the taggable.
  #
  def destroy
    respond_to do |wants|
      tagging = params[:tagging]
      @feed_item = FeedItem.find(tagging[:feed_item_id])
      
      current_user.taggings.find_by_feed_item(@feed_item, :all, 
                                            :conditions => {:tag_id => Tag(current_user, tagging[:tag]).id}).
                                            each(&:destroy)
    
      wants.js
    end
  end
end
