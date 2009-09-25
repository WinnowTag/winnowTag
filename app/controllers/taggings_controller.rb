# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Required for the +Tag()+ function.  Rails can sometimes auto-load this and
# sometimes it doesn't so lets put it here explicitly so we can always be
# sure it has been loaded and the +Tag()+ function is available.
# require 'tag.rb'

# Not explicitly requiring the file because is causes problems with reloading
# in development mode. Using this contstant allows rails to auto load the 
# +Tag+ class, and therefore the +Tag()+ function
Tag

# The +TaggingsController+ is used to manage user taggings on feed items.
class TaggingsController < ApplicationController
  # The +create+ action creates a single +Tagging+ for a 
  # <tt><FeedItem, User, Tag></tt> combination. Any existing
  # tagging for that combination will be deletd. If the Tag 
  # is not already in the users sidebar, it will be added.
  def create
    tag = Tag(current_user, params[:tagging][:tag])
    Tagging.transaction do
      @tagging = Tagging.new(params[:tagging].merge(:tag => tag, :user => current_user))
      if @tagging.save
        unless tag.show_in_sidebar?
          tag.update_attribute(:show_in_sidebar, true)
        end
        respond_to :json
      else
        respond_to do |format|
          format.json { render :action => "error.json.erb" }
        end
      end
    end
  end
  
  # The +destroy+ action destroys a user tagging on a FeedItem.
  #
  # Accepted Parameters:
  #
  # - +tagging+:
  #   - +feed_item_id+: The id of a +FeedItem+ to destroy a +Tagging+ on.
  #   - +tag+:          The name of the +Tag+ to destroy the +Tagging+ on the +FeedItem+.
  def destroy
    @feed_item = FeedItem.find(params[:tagging][:feed_item_id])
    @tag = Tag(current_user, params[:tagging][:tag])
    
    current_user.taggings.find_by_feed_item(@feed_item, :all, 
      :conditions => { :classifier_tagging => false, :tag_id => @tag }).each(&:destroy)            

    respond_to :json
  end
end
