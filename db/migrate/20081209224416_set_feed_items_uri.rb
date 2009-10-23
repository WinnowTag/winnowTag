# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class SetFeedItemsUri < ActiveRecord::Migration
  def self.up
    execute "update feed_items set uri = concat('urn:peerworks.org:entry#', id)"
  end

  def self.down
  end
end
