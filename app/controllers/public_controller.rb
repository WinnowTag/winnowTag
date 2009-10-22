# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +PublicController+ is publically accessible and does not require any
# user to be logged in.
class PublicController < ApplicationController
  skip_before_filter :login_required

  # The +ie6+ action is used to display a message to users who
  # are trying to access Winnow using the unsupported IE6 browser.
  def ie6
    render :layout => "ie6"
  end
end