# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ItemProtectionController < ApplicationController
  permit 'admin'
  
  def show
    begin
      @protector = Protector.protector(request.host)
    rescue ActiveResource::ConnectionError
      flash.now[:error] = _(:item_protection_status)
      render :nothing => true, :status => :not_found
    end
  end
  
  def rebuild
    begin
      Remote::ProtectedItem.rebuild
      redirect_to item_protection_path      
    rescue ActiveResource::ConnectionError => e
      flash[:error] = _(:item_protection_rebuild_failure, e.message)
      redirect_to item_protection_path
    end
  end
end
