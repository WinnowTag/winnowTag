# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +FoldersController+ is used to support the folders feature on the 
# feed items sidebar.
class FoldersController < ApplicationController
  def create
    @folder = current_user.folders.create!(params[:folder])
    respond_to :js
  end
  
  def update
    @folder = current_user.folders.find(params[:id])
    @folder.update_attributes!(params[:folder])
    respond_to :js
  end
  
  def destroy
    @folder = current_user.folders.find(params[:id]).destroy
    respond_to :js
  end
  
  # The +add_item+ action is used to add a tag or feed to the sidebar.
  def add_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @feed = Feed.find($1)
        @folder.feeds << @feed
      when /^tag_(\d+)$/
        @tag = Tag.find($1)
        @folder.tags << @tag
    end
    respond_to :js
  end
  
  # The +remove_item+ action is used to remove a tag or feed from the sidebar.
  def remove_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @folder.feed_ids -= [$1.to_i]
      when /^tag_(\d+)$/
        @folder.tag_ids -= [$1.to_i]
    end
    render :nothing => true
  end
  
  # The +sort+ action is used to reorder the folder within the sidebar.
  def sort
    params[:folders].each_with_index do |id, index|
      Folder.find(id).update_attribute(:position, index + 1)
    end
    render :nothing => true    
  end
end
