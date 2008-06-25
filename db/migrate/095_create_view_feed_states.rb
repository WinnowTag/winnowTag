# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CreateViewFeedStates < ActiveRecord::Migration
  def self.up
    create_table :view_feed_states do |t|
      t.column :view_id, :integer
      t.column :state, :string
      t.column :feed_id, :integer
    end
  end

  def self.down
    drop_table :view_feed_states
  end
end
