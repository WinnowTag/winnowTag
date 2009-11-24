# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module Remote
  # Represents a classifier in the Classifier.
  class Classifier < ClassifierResource
    self.element_name = ""
    def self.get_info
      new(self.connection.get("/classifier.xml"))
    end
  end
end
