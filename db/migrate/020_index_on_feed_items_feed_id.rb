class IndexOnFeedItemsFeedId < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :feed_id
    add_index :feed_items, :title
  end

  def self.down
    remove_index :feed_items, :feed_id
    remove_index :feed_items, :title
  end
end
