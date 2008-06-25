# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module Remote
  class Classifier < ClassifierResource
    self.element_name = ""
    def self.get_info
      new(self.connection.get("/classifier.xml"))
    end
  end
end
