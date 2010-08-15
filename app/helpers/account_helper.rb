# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module AccountHelper
  def stay_signed_in_cookie
    cookies[:stay_signed_in]
  end  
end
