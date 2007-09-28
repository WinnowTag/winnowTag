# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class BulkTaggingsController < ApplicationController
  verify :method => :post, :redirect_to => :back, 
         :add_flash => {:error => 'Action can not be called with HTTP get'}
  
  def create
    @bulk_tagging = BulkTagging.create(:filter => Feed.find(params[:filter]), 
                       :tag => params[:tag], 
                       :tagger => current_user,
                       :exclusive => params[:exclusive] == true)
    flash[:error] = "Could not create BulkTagging: #{@bulk_tagging.errors}" unless @bulk_tagging.valid?
    redirect_to :back
  end

  def destroy
    BulkTagging.destroy_for(Feed.find(params[:filter]), current_user, Tag.find_or_create_by_name(params[:tag]))
    redirect_to :back
  end
end
