class FoldersController < ApplicationController

  def create
    @folder = current_user.folders.create!(params[:folder])
    respond_to :js
  end
  
  def update
    @folder = current_user.folders.find(params[:id])
    @folder.attributes = params[:folder]
    @folder.save!
    respond_to :js
  end
  
  def destroy
    @folder = current_user.folders.destroy(params[:id])
    respond_to :js
  end
  
  def add_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @folder.feed_ids += [$1]
      when /^tag_(\d+)$/
        @folder.tag_ids += [$1]
    end
    @folder.save!
    respond_to :js
  end
end
