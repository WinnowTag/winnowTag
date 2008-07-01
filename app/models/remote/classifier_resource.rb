# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  class ClassifierResource < ActiveResource::Base
    self.logger = ActiveRecord::Base.logger
    self.timeout = 5
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'classifier-client.conf'))
    rescue
      self.site = "http://localhost:8008/classifier"
    end
  end  
end