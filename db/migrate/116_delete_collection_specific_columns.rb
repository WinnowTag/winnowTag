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

class DeleteCollectionSpecificColumns < ActiveRecord::Migration
  def self.up
    remove_column :feeds, :last_http_headers
   # remove_column :feeds, :collection_errors_count

    remove_column :feed_items, :time_source
    remove_column :feed_items, :xml_data_size
   #  remove_column :feed_items, :tokens_were_spidered
    remove_column :feed_items, :content_length
    remove_column :feed_items, :unique_id
    add_column :feed_items, :title, :string

    execute "update feed_items set title = (select title from feed_item_contents where feed_item_id = feed_items.id limit 1)"
    
    remove_column :feed_item_contents, :created_on
    remove_column :feed_item_contents, :link
    remove_column :feed_item_contents, :title
    remove_column :feed_item_contents, :description
    
  end

  def self.down
    raise IrreversibleMigration
  end
end
