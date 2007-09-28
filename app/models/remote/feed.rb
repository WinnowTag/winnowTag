# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class Feed < CollectorResource    
    def collect(options = {})
      Remote::CollectionJob.create(options.merge(:feed_id => self.id))
    end
  end
end