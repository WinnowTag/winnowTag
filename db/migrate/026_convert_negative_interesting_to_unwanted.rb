# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class ConvertNegativeInterestingToUnwanted < ActiveRecord::Migration
  class Tag < ActiveRecord::Base; end
  def self.up
    interesting = Tag.find_or_create_by_name('interesting')
    unwanted = Tag.find_or_create_by_name('unwanted')
    Tagging.transaction do
      execute "insert into taggings " +
              "(tag_id, tagger_id, tagger_type, taggable_id, taggable_type, strength, created_on, metadata_type, metadata_id)" +
              "(select #{unwanted.id}, tagger_id, tagger_type, taggable_id, taggable_type, " + 
              "1, created_on, metadata_type, metadata_id from taggings " +
              "where tag_id = #{interesting.id} and strength = 0 and deleted_at is null);"
      execute "update taggings set deleted_at = NOW() where tag_id = #{interesting.id} and strength = 0 and deleted_at is null;"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Unable to restore negative interesting taggings from unwanted'
  end
end
