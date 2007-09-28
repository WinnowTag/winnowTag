# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddUserTimezone < ActiveRecord::Migration
  def self.up
    add_column :users, :time_zone, :string, :default => 'UTC'
  end

  def self.down
    remove_column :users, :time_zone
  end
end
