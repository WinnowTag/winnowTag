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
        unless @folder.feed_ids.include?($1.to_i)
          @folder.feed_ids += [$1]
          @feed = Feed.find($1)
        end
      when /^tag_(\d+)$/
        unless @folder.tag_ids.include?($1.to_i)
          @folder.tag_ids += [$1]
          @tag = Tag.find($1)
        end
    end
    @folder.save!
    render :nothing => true
  end
  
  def remove_item
    @folder = current_user.folders.find(params[:id])
    case params[:item_id]
      when /^feed_(\d+)$/
        @folder.feed_ids -= [$1.to_i]
      when /^tag_(\d+)$/
        @folder.tag_ids -= [$1.to_i]
    end
    @folder.save!
    render :nothing => true
  end
end
