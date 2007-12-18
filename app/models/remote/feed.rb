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
    
    def self.import_opml(opml)
      response = connection.post(custom_method_collection_url(:import_opml), opml, 'Content-Type' => 'text/x-opml')
      format.decode(response.body).map do |attributes|
        new(attributes)
      end
    end
     
    def collect(options = {})
      Remote::CollectionJob.create(options.merge(:feed_id => self.id))
    end    
  end
end