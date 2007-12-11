# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class ClassifierResource < ActiveResource::Base
    self.logger = ActiveRecord::Base.logger
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'classifier-client.conf'))
    rescue
      self.site = "http://localhost:8008/classifier"
    end
  end  
end