# Copyright (c) 2005 Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# Contains a set of custom validations created by Peerworks

module Peerworks
  module Validations
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def validates_difference_between(*attrs)
        attrs.each do |attr_name|
          validate do |record|
            attrs.each do |name_to_compare|
              if attr_name != name_to_compare and record.send(attr_name) == record.send(name_to_compare) and
                  record.errors[name_to_compare] == nil # don't add duplicate inverse errors
                record.errors.add(attr_name, "cannot be the same as #{name_to_compare.to_s.humanize}")
                break
              end
            end
          end
        end
      end
    end
  end
end