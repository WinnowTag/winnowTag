# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module TagsHelper
  include BiasSliderHelper  
  def cancel_link
    if request.xhr?
      link_to_function 'Cancel', visual_effect(:blind_up, dom_id(@tag, 'form'), :duration => 0.3)
    else
      link_to "Cancel", tags_url
    end
  end
end
