# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
