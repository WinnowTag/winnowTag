# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class ClassifierJob < ActiveResource::Base
    class Status
      WAITING = "Waiting"
      COMPLETE = "Complete"
    end
    self.element_name = "job"
    self.logger = ActiveRecord::Base.logger
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'classifier-server.conf'))
    rescue
      self.site = "http://localhost:8008/classifier"
    end
  end
end
