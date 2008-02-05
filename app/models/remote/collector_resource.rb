# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class CollectorResource < ActiveResource::Base
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'collector.conf'))
    rescue
      self.site = "http://collector.wizztag.org"
    end
    
    def self.with_redirect(limit = 5)      
      begin
        yield
      rescue ActiveResource::Redirection => redirect
        raise redirect if limit < 0
        # try and get the id
        if id = redirect.response['Location'][/\/([^\/]*?)(\.\w+)?$/, 1]
          with_redirect(limit - 1) do
            self.find(id)
          end
        else
          raise ActiveResource::RecordNotFound, redirect.response
        end
      end
    end
  end
end