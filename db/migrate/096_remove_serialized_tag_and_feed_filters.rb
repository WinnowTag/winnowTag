class RemoveSerializedTagAndFeedFilters < ActiveRecord::Migration
  def self.up
    remove_column :views, :tag_filter
    remove_column :views, :feed_filter
  end

  def self.down
    add_column :views, :tag_filter, :text
    add_column :views, :feed_filter, :text
  end
end
