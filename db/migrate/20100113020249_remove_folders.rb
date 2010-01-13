# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveFolders < ActiveRecord::Migration
  def self.up
    drop_table :folders_tags
    drop_table :feeds_folders
    drop_table :folders
  end

  def self.down
    create_table "folders", :force => true do |t|
      t.string   "name"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
    end

    create_table "feeds_folders", :id => false, :force => true do |t|
      t.integer "folder_id"
      t.integer "feed_id"
    end
    
    create_table "folders_tags", :id => false, :force => true do |t|
      t.integer "folder_id"
      t.integer "tag_id"
    end    
  end
end
