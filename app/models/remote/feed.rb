# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  class Feed < CollectorResource  
    def self.find_with_redirect(id)
      with_redirect do 
        self.find(id)
      end
    end
    
    def self.find_or_create_by_url_and_created_by(url, created_by)
      with_redirect do
        self.create(:url => url, :created_by => created_by)
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
    
    # Write some of my own attribute getters so they exist when ActiveResource doesnt map write them for us
    %w[link url updated_on duplicate].each do |attribute|
      define_method(attribute) do
        attributes[attribute]
      end
    end
    
    # some handy functions that map the collectors schema into the atom'ish schema used by Winnow
    def alternate
      self.link
    end
    
    def via
      self.url
    end
    
    def title
      if not attributes["title"].blank?
        attributes["title"]
      elsif not alternate.blank?
        URI.parse(alternate).host
      elsif not via.blank?
        URI.parse(via).host
      end
    end

    # This is needed so that the Remote::Feed has the same API as the local Feed model.
    def feed_items
      []
    end
  end
end