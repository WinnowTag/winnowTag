# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class UpdateFeedsTitleFromAlternateOrVia < ActiveRecord::Migration
  def self.up
    Feed.find_each do |feed|
      feed.save!
    end
  end

  def self.down
  end
end
