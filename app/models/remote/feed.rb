# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Remote
  # Represents a Feed in the Collector.
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
    
    # Request the Collector to import the requested OPML data.
    def self.import_opml(opml, created_by = nil)
      if created_by
        options = {:created_by => created_by}
      else
        options = {}
      end
      response = connection.post(custom_method_collection_url(:import_opml, options), opml, 'Content-Type' => 'text/x-opml')
      format.decode(response.body).map do |attributes|
        new(attributes)
      end
    end
     
    # Request the Collector to make a collection of this feed.
    def collect(options = {})
      Remote::CollectionJob.create(options.merge(:feed_id => self.id))
    end  
    
    # Write some of attribute getters so they exist when ActiveResource doesn't write them for us
    %w[link url updated_on duplicate].each do |attribute|
      define_method(attribute) do
        attributes[attribute]
      end
    end

    # This is needed so that the Remote::Feed has the same API as the local Feed model.
    def feed_items
      []
    end
    
    # Alias some attributes to map the collectors schema into the atom'ish schema used by Winnow
    alias_method :alternate, :link
    alias_method :via, :url
    
    # Override the title attribute to return one of the urls
    # if no title is present.
    def title
      if not attributes["title"].blank?
        attributes["title"]
      elsif not alternate.blank?
        URI.parse(alternate).host
      elsif not via.blank?
        URI.parse(via).host
      end
    end
  end
end