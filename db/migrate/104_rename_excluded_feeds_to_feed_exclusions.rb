class RenameExcludedFeedsToFeedExclusions < ActiveRecord::Migration
  def self.up
    rename_table :excluded_feeds, :feed_exclusions
  end

  def self.down
    rename_table :feed_exclusions, :excluded_feeds
  end
end
