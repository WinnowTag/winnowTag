class AddUniqueIndexToFeedSubscriptions < ActiveRecord::Migration
  def self.up
    add_index :feed_subscriptions, [:feed_id, :user_id], :unique => true
  end

  def self.down
    remove_index :feed_subscriptions, :column => :feed_id
  end
end
