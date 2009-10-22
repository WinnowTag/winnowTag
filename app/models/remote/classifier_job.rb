# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  # Represents a classifier job in the Classifier.
  class ClassifierJob < ClassifierResource
    with_auth_hmac(HMAC_CREDENTIALS['winnow'])
    self.element_name = "job"
    class Status
      WAITING = "Waiting"
      COMPLETE = "Complete"
      ERROR = "Error"
    end
  end
end
