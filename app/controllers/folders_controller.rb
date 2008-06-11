# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class FoldersController < ApplicationController
  def create
    @folder = current_user.folders.create!(params[:folder])
    respond_to :js
  end
  
  def update
    @folder = current_user.folders.find(params[:id])
    @folder.update_attributes!(params[:folder])
    render :text => @folder.name
  end
  
  def destroy
    @folder = current_user.folders.destroy(params[:id])
    respond_to :js
  end
  
  def add_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @folder.add_feed!($1)
        @feed = Feed.find($1)
      when /^tag_(\d+)$/
        @folder.add_tag!($1)
        @tag = Tag.find($1)
    end
    respond_to :js
  end
  
  def remove_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @folder.remove_feed!($1)
      when /^tag_(\d+)$/
        @folder.remove_tag!($1)
    end
    render :nothing => true
  end
  
  def sort
    params[:folders].each_with_index do |id, index|
      Folder.find(id).update_attribute(:position, index+1)
    end
    render :nothing => true    
  end
end
