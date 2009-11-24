# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddSortNameToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :sort_name, :string

    Tag.find_each do |tag|
      tag.save!
    end
  end

  def self.down
    remove_column :tags, :sort_name
  end
end
