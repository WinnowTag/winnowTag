# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class AddUriColumnToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :uri, :string
    add_index :feeds, [:uri], :unique => true
  end

  def self.down
    remove_column :feeds, :uri
  end
end
