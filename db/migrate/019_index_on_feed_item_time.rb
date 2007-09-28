class IndexOnFeedItemTime < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :time
  end

  def self.down
    remove_index :feed_items, :time
  end
end
