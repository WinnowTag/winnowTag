class AddIndexToTaggingsOnTagIdAndFeedItemId < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:tag_id, :feed_item_id]
  end

  def self.down
    remove_index :taggings, [:tag_id, :feed_item_id]
  end
end
