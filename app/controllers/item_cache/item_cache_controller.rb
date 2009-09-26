# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# TODO: Sean to document
module ItemCache
  class ItemCacheController < ApplicationController
    skip_before_filter :login_required
    with_auth_hmac HMAC_CREDENTIALS['collector']
    before_filter :check_atom
  end
end
