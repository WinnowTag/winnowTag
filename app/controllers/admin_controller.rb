# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AdminController < ApplicationController
  permit 'admin'

  def index
  end
  
  def using
    @using = Setting.find_or_initialize_by_name("Using Winnow")
    if request.post?
      @using.value = params[:value]
      @using.save!
      redirect_to using_path
    end
  end
end
