# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AdminController < ApplicationController
  permit 'admin'

  def index
  end
  
  def info
    @info = Setting.find_or_initialize_by_name("Info")
    if request.post?
      @info.value = params[:value]
      @info.save!
      redirect_to info_path
    end
  end
  
  def help
    @help = Setting.find_or_initialize_by_name("Help")
    if request.post?
      @help.value = params[:value]
      @help.save!
      redirect_to admin_path
    end
  end
end
