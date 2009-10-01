# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# The +AdminController+ is only accessible by admin users. Many of the
# admin-only features are housed in other controllers, but some of the 
# misc actions are housed here.
class AdminController < ApplicationController
  permit 'admin'

  # The +index+ action is the default landing page for the admin
  # section. It displays a list of links to the available admin
  # pages.
  def index
  end
  
  # The +info+ action is used to edit the content on the info page.
  def info
    @info = Setting.find_or_initialize_by_name("Info")
    if request.post?
      @info.value = params[:value]
      @info.save!
      redirect_to info_path
    end
  end
  
  # The +help+ action is used to edit the help links displayed 
  # thoroughout winnow. A default help link can be set, as well
  # as per-page help links.
  def help
    @help = Setting.find_or_initialize_by_name("Help")
    if request.post?
      @help.value = params[:value]
      @help.save!
      redirect_to admin_path
    end
  end
end
