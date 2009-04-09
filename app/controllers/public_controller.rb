# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class PublicController < ApplicationController
  skip_before_filter :login_required

  def ie6
    render :template => "public/ie6", :layout => "ie6"
  end
end