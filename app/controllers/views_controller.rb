# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class ViewsController < ApplicationController
  skip_before_filter :load_view, :only => :create
  
  def add_feed
    @view.add_feed params[:feed_state], params[:feed_id]
    @view.save!
    render :nothing => true
  end
  
  def remove_feed
    @view.remove_feed params[:feed_id]
    @view.save!
    render :nothing => true
  end
  
  def add_tag
    @view.add_tag params[:tag_state], params[:tag_id]
    @view.save!
    render :nothing => true
  end
  
  def remove_tag
    @view.remove_tag params[:tag_id]
    @view.save!
    render :nothing => true
  end
  
  def edit
  end
  
  def update
    @view.update_attributes params[:view].merge(:state => "saved")
    @redirect = params[:redirect].to_s =~ /true/i
  end
  
  def destroy
    @view.destroy
  end
  
  def create
    @new_view = current_user.views.create!
    @redirect = true
  end
  
  def duplicate
    @new_view = @view.dup!
    @redirect = true
  end
  
private

  def load_view
    @view = current_user.views.find(params[:id])
  end
end
