class FoldersController < ApplicationController
  def create
    @folder = current_user.folders.new(params[:folder])

    respond_to do |format|
      if @folder.save
        format.js
      else
        format.js { render :action => "error" }
      end
    end
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
      when /^tag_(\d+)$/
        @folder.add_tag!($1)
    end
    render :nothing => true
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
end
