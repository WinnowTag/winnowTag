# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class ChangeBiasDefaultTo11 < ActiveRecord::Migration
  def self.up
    change_column_default(:tags, :bias, 1.1)
  end

  def self.down
    change_column_default(:tags, :bias, 1.2)
  end
end
