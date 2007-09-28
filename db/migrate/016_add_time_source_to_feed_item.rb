class AddTimeSourceToFeedItem < ActiveRecord::Migration
  def self.up
    add_column "feed_items", "time_source", :string, :default => FeedItem::UnknownTimeSource
  end

  def self.down
    remove_column "feed_items", "time_source"
  end
end
