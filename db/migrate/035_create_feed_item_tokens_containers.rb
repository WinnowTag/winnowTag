# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateFeedItemTokensContainers < ActiveRecord::Migration
  def self.up
    create_table :feed_item_tokens_containers do |t|
      t.column :feed_item_id, :integer
      t.column :created_on, :datetime
      t.column :tokens, :text
      t.column :tokenizer_version, :integer
    end
    
    add_index :feed_item_tokens_containers, :feed_item_id
  end

  def self.down
    drop_table :feed_item_tokens_containers
  end
end
