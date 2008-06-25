# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.

# This just stores the id for this Winnow's protector instance
# in the collection database.
class Protector < ActiveRecord::Base
  validate_on_create :validates_as_singleton
  
  def self.id
    if protector = Protector.find(:first)
      protector.protector_id
    end
  end
  
  def self.protector(protector_name = nil)
    if id = self.id
      Remote::Protector.find(id)
    elsif protector_name
      protector = Remote::Protector.create(:name => protector_name).reload
      self.create(:protector_id => protector.id)
      protector
    end
  end
  
  protected
  def validates_as_singleton
    if Protector.count > 0
      # TODO: localization
      self.errors.add_to_base("A Protector already exists, there can be only one!")
    end
  end
end
