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


# This migration extracts the title, author, link, time and description
# properties out of the xml data of a feed and stores it in the 
# feed_item_contents table.  This is in a separate migration because it
# maybe a very long running migration and I want to isolate schema changes
# from data changes.
#
# Creates the feed item contents table to store contents of a feed item.
# The table also uses the MyISAM engine to allow fo text indexing at a
# later stage.
class CreateFeedItemContents < ActiveRecord::Migration
  # AR class for migrations
  class FeedItemContent < ActiveRecord::Base
    belongs_to :feed_item
  end
  class FeedItem < ActiveRecord::Base
    has_one :feed_item_content
  end
  
  def self.up
    create_table "feed_item_contents", :options => 'ENGINE=MyISAM' do |t|
      t.column "feed_item_id", :integer
      t.column "title", :text # title is here for text indexing too
      t.column "link", :string
      t.column "author", :string
      t.column "description", :longtext
    end
    
    add_index "feed_item_contents", "feed_item_id"
  end  

  def self.down
    drop_table "feed_item_contents"
  end
end
