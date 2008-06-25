# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.

# Required for the Tag() function.  Rails can sometimes auto-load this and
# sometimes it doesn't so lets put it here explicitly so we can always be
# sure it has been loaded and the Tag and function is available.
# require 'tag.rb'

# Not explicitly requiring the file because is causes problems with reloading
# in development mode. Using this contstant allows rails to auto load the 
# Tag class, and therefore the Tag() function
Tag

class TaggingsController < ApplicationController
  helper :feed_items

  verify :method => :post, :render => {
    :text => _(:bad_method), :status => 400
  }
  verify :params => :tagging, :render => {
    :text => _(:bad_params), :status => 400
  }
  
  # Creates a single tagging for a <Taggable, Tagger, Tag>
  def create
    params[:tagging][:tag] = Tag(current_user, params[:tagging][:tag])
    @tagging = current_user.taggings.create!(params[:tagging])
    @feed_item = @tagging.feed_item
    respond_to :js
  end
  
  # Destroys taggings
  #
  #  Accepted Parameters:
  #    - tagging: 
  #         feed_item_id: The type and id of a taggable to destroy a tagging on.
  #         tag: The name of the tag to destroy the tagging on the taggable.
  def destroy
    @feed_item = FeedItem.find(params[:tagging][:feed_item_id])
    @tag = Tag(current_user, params[:tagging][:tag])
    
    current_user.taggings.find_by_feed_item(@feed_item, :all, 
      :conditions => { :classifier_tagging => false, :tag_id => @tag }).each(&:destroy)            

    respond_to :js
  end
end
