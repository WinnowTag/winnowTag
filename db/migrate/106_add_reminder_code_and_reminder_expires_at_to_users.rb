# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddReminderCodeAndReminderExpiresAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :reminder_code, :string
    add_column :users, :reminder_expires_at, :datetime
  end

  def self.down
    remove_column :users, :reminder_expires_at
    remove_column :users, :reminder_code
  end
end
