# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RenameExcludedFeedsToFeedExclusions < ActiveRecord::Migration
  def self.up
    rename_table :excluded_feeds, :feed_exclusions
  end

  def self.down
    rename_table :feed_exclusions, :excluded_feeds
  end
end
