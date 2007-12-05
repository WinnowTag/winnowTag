# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ChangeBiasDefault < ActiveRecord::Migration
  def self.up
    change_column_default(:tags, :bias, 1.2)
  end

  def self.down
    change_column_default(:tags, :bias, 1.0)
  end
end
