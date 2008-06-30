# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class TimestampFieldConsistency < ActiveRecord::Migration
  def self.up
    add_column "classifiers_users", "created_on", :datetime
    add_column "classifiers_tags", "created_on", :datetime
    add_column "feed_item_contents", "created_on", :datetime
    rename_column "feed_items", "time_retrieved", "created_on"
    rename_column "feeds", "time_last_retrieved", "updated_on"
    add_column "feeds", "created_on", :datetime
  end

  def self.down
    rename_column "feed_items", "created_on", "time_retrieved"
    remove_column "classifiers_tags", "created_on"
    remove_column "classifiers_users", "created_on"
    remove_column "feed_item_contents", "created_on"
    rename_column "feeds", "updated_on", "time_last_retrieved"
    remove_column "feeds", "created_on"
  end
end
