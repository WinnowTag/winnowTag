# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ItemProtectionController < ApplicationController
  permit 'admin'
  
  def show
    begin
      @protector = Protector.protector(request.host)
    rescue ActiveResource::ConnectionError
      flash.now[:error] = "Unable to fetch protection status from the collector"
      render :template => 'shared/error', :status => :not_found
    end
  end
  
  def rebuild
    begin
      Remote::ProtectedItem.rebuild
      redirect_to item_protection_path      
    rescue ActiveResource::ConnectionError => e
      flash[:error] = "Could not rebuild item protection: #{e.message}"
      redirect_to item_protection_path
    end
  end
end
