# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  # This is a base class used to define the configuration necessary to 
  # communicate with the collector.
  class CollectorResource < ActiveResource::Base
    with_auth_hmac(HMAC_CREDENTIALS['winnow'])
    
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'collector.conf'))
    rescue
      self.site = "http://collector.mindloom.org"
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