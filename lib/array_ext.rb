# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Array #:nodoc:

  # Patch to Array to allow indexing by an attribute
  def hash_by(attribute)
    self.inject({}) do |hash, e|
      hash[e.send(attribute)] = e
      hash
    end
  end
end