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


class OptimizeTaggingIndexes < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:feed_item_id, :tag_id, :classifier_tagging], :unique => true

    remove_index :taggings, :name => 'user_tag_item_classifier'                         rescue say("error deleting user_tag_item_classifier")
    remove_index :taggings, :name => 'user_item_tag_classifier'                         rescue say("error deleting user_item_tag_classifier")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_feed_item_id'        rescue say("error deleting index_taggings_on_tag_id_and_feed_item_id")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_classifier_tagging'  rescue say("error deleting index_taggings_on_tag_id_and_classifier_tagging")
    remove_index :taggings, :name => 'index_taggings_on_tag_id_and_created_on'          rescue say("error deleting index_taggings_on_tag_id_and_created_on")
    remove_index :taggings, :name => 'item_tag_strength_classifier'                     rescue say("error deleting item_tag_strength_classifier")
    remove_index :taggings, :name => 'index_taggings_on_user_id_and_classifier_tagging' rescue say("error deleting index_taggings_on_user_id_and_classifier_tagging")

    execute "optimize table taggings"
  end

  def self.down
    remove_index :taggings, :column => [:feed_item_id, :tag_id, :classifier_tagging]
  end
end
