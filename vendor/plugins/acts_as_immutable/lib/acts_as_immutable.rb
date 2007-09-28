# Copyright (c) 2005 Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Peerworks #:nodoc:
  module ActsAsImmutable #:nodoc:
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_immutable
        include InstanceMethods
        before_update :immutable
      end
      
      module InstanceMethods
        def immutable
          logger.warn "Tried to update an immutable #{self.class.name} object"
          false
        end
      end
    end
  end
end
  