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

class ReIndexTaggingsTable < ActiveRecord::Migration
  def self.up
#    remove_index :taggings, :name => :taggings_taggable_id_index
#    remove_index :taggings, :name => :taggings_tagger_id_index
#    remove_index :taggings, :name => :taggings_tag_id_index
#    remove_index :taggings, :name => :taggings_deleted_at_index
    
    add_index :taggings, [:tagger_id, :tagger_type, :deleted_at, 
                          :tag_id, :strength, :train_count], 
                          :name => "tagger_index"
    add_index :taggings, [:taggable_id, :taggable_type, :deleted_at, 
                          :user_id, :tag_id, :tagger_type, :strength, 
                          :train_count], :name => "taggable_index"
    execute 'optimize table taggings;'
    execute 'analyze table taggings;'
  end

  def self.down
    add_index :taggings, :taggable_id
    add_index :taggings, :tagger_id
    add_index :taggings, :tag_id
    add_index :taggings, :deleted_at
    remove_index :taggings, :name => :tagger_index
    remove_index :taggings, :name => :taggable_index
  end
end
