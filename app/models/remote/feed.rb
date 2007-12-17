# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class Feed < CollectorResource  
    def self.find_with_redirect(id)
      with_redirect do 
        self.find(id)
      end
    end
    
    def self.find_or_create_by_url(url)
      with_redirect do
        self.create(:url => url)
      end
    end
        
    def collect(options = {})
      Remote::CollectionJob.create(options.merge(:feed_id => self.id))
    end
  end
end