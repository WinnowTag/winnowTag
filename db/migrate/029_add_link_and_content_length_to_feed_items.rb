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

class AddLinkAndContentLengthToFeedItems < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :link, :string
    add_column :feed_items, :content_length, :integer
    add_index :feed_items, :link # index used for deletion of dups
    
    FeedItem.transaction do
      say "Removing items without links"
      execute <<-END_DELETE
        delete 
          feed_items, feed_item_contents
          from feed_items 
          join feed_item_contents 
            on feed_items.id = feed_item_contents.feed_item_id 
          where feed_item_contents.link is null;
      END_DELETE
      
      say "Populating link and content length columns"
      execute <<-END_UPDATE
        update feed_items 
          join feed_item_contents
            on feed_items.id = feed_item_contents.feed_item_id
          set
            feed_items.link = feed_item_contents.link,
            feed_items.content_length = CHAR_LENGTH(feed_item_contents.encoded_content);
      END_UPDATE
      
      say "Removing duplicates by link, keeping the most recent one."
      execute <<-END_DELETE
        delete
          t1, t3
          from feed_items t1, feed_items t2, feed_item_contents t3
          where 
            t1.id = t3.feed_item_id
              and
            t1.link = t2.link
              and
            t1.id < t2.id                          
      END_DELETE
    end
    
    # remove temp index and setup one with unique
    remove_index :feed_items, :link 
    add_index :feed_items, :link, :unique => true
    add_index :feed_items, :content_length
  end

  def self.down
    remove_column :feed_items, :link
    remove_column :feed_items, :content_length
    remove_index :feed_items, :column => :link
    remove_index :feed_items, :content_length
  end
end
