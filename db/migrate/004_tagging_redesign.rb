# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# This migration marks the beginning of the use of the new tagging design.
# Documentation for this tagging design can be found at 
# http://trac.winnow.peerworks.org/wiki/TaggingDesign
#
# This is an irreversible migration that will destroy the old
# tagging tables and any tag data in them.
class TaggingRedesign < ActiveRecord::Migration
  def self.up
    # start by destroying old tags and tagging tables
    drop_table "tags"
    drop_table "tags_seed_items"
    
    create_table "tags" do |t|
        t.column "name", :string
    end
    
    create_table "taggings" do |t|
        t.column "taggable_type", :string
        t.column "taggable_id", :integer
        t.column "tagger_type", :string
        t.column "tagger_id", :integer
        t.column "created_on", :datetime
        t.column "tag_id", :integer
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
