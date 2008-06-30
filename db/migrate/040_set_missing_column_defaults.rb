# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Sets a number of missing column defaults since Rails 1.2 is much more
# strict in this regard.
class SetMissingColumnDefaults < ActiveRecord::Migration
  def self.up
    change_column_default(:rename_taggings, :number_renamed, 0)
    change_column_default(:rename_taggings, :number_left, 0)
  end

  def self.down
  end
end
