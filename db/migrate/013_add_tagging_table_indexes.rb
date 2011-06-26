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

class AddTaggingTableIndexes < ActiveRecord::Migration
  def self.up
    add_index :taggings, :deleted_at
    add_index :taggings, :tagger_id
    add_index :taggings, :taggable_id
    add_index :taggings, :tag_id
    add_index :tags, :name, :unique => true
    execute('alter table classifiers_tags add primary key (classifier_id, tag_id);')
    execute('alter table classifiers_users add primary key (classifier_id, user_id);')
  end

  def self.down
    remove_index :taggings, :deleted_at
    remove_index :taggings, :tagger_id
    remove_index :taggings, :taggable_id
    remove_index :taggings, :tag_id
    remove_index :tags, :name, :unique => true
    execute('alter table classifiers_tags add primary key (classifier_id, tag_id);')
    execute('alter table classifiers_users add primary key (classifier_id, user_id);')
  end
end
