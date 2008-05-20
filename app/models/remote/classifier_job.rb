# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module Remote
  class ClassifierJob < ClassifierResource
    self.element_name = "job"
    class Status
      WAITING = "Waiting"
      COMPLETE = "Complete"
      ERROR = "Error"
    end
  end
end
