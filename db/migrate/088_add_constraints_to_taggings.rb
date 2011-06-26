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

class AddConstraintsToTaggings < ActiveRecord::Migration
  def self.up    
    change_column :taggings, :tag_id, :integer, :null => false
    change_column :taggings, :feed_item_id, :integer, :null => false
    change_column :taggings, :strength, :float, :null => false
    
    # Might have old indexes in place
    execute "alter ignore table taggings drop index tagger_index;"
    execute "alter ignore table taggings drop index taggable_index;"
    
    # First do some cleaning up    
    execute "delete from taggings where user_id = 0;"
    execute "delete from taggings where tag_id not in (select id from tags);"
    
    execute "alter table taggings add foreign key (tag_id) references tags(id) on delete cascade;"
    execute "alter table taggings add foreign key (user_id) references users(id) on delete cascade;"
    # Can't put one on feed_items because it is not an InnoDB table
    # execute "alter table taggings add foreign key (feed_item_id) references feed_items(id) on delete cascade;"
  end

  def self.down
  end
end
