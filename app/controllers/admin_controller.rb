# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
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
end
