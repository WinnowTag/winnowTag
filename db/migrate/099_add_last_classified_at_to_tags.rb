# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddLastClassifiedAtToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :last_classified_at, :datetime
    
    execute "update tags set last_classified_at = (" +
              "select max(created_on) from taggings where tag_id = tags.id and classifier_tagging = 1)"
    
  end

  def self.down
    remove_column :tags, :last_classified_at
  end
end
