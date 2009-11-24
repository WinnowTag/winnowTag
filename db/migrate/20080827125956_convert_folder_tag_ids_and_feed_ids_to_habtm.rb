# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertFolderTagIdsAndFeedIdsToHabtm < ActiveRecord::Migration
  class Folder < ActiveRecord::Base; end
  
  def self.up
    create_table :folders_tags, :id => false do |t|
      t.integer :folder_id, :tag_id
    end
    
    create_table :feeds_folders, :id => false do |t|
      t.integer :folder_id, :feed_id
    end
    
    Folder.find(:all).each do |folder|
      folder.tag_ids.to_s.split(",").each do |tag_id|
        execute("INSERT INTO folders_tags(folder_id, tag_id) VALUES(#{folder.id}, #{tag_id})") if Tag.exists?(tag_id)
      end
      
      folder.feed_ids.to_s.split(",").each do |feed_id|
        execute("INSERT INTO feeds_folders(folder_id, feed_id) VALUES(#{folder.id}, #{feed_id})") if Feed.exists?(feed_id)
      end
    end
    
    remove_column :folders, :tag_ids
    remove_column :folders, :feed_ids
  end

  def self.down
    add_column :folders, :tag_ids, :string
    add_column :folders, :feed_ids, :string

    say("Not moving tag/feed lists back to the feeds table")
    
    drop_table :folders_tags
    drop_table :feeds_folders
  end
end
