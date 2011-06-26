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

class TableRename < ActiveRecord::Migration
  def self.up
    drop_table :feeds
    rename_table :seeds, :feeds
    rename_table :seed_items, :feed_items
    
    rename_column :feed_items, :seed_id, :feed_id
    rename_column :tags_seed_items, :seed_item_id, :feed_item_id
  end

  def self.down
    rename_column :tags_seed_items, :feed_item_id, :seed_item_id
    rename_column :feed_items, :feed_id, :seed_id
    rename_table :feeds, :seeds
    rename_table :feed_items, :seed_items
    
    # SBG I don't think this is actually needed but it is in
    #     the original schema so I'm putting it here incase
    create_table "feeds" do |t|
      t.column "url", :string
      t.column "title", :string, :null => true
      t.column "link", :string, :null => true
      t.column "xml_data", :longtext
      t.column "http_headers", :text
      t.column "last_retrieved", :datetime, :null => true
    end
  end
end
