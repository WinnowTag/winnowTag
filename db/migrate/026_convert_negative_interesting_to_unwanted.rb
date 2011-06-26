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

class ConvertNegativeInterestingToUnwanted < ActiveRecord::Migration
  class Tag < ActiveRecord::Base; end
  def self.up
    interesting = Tag.find_or_create_by_name('interesting')
    unwanted = Tag.find_or_create_by_name('unwanted')
    Tagging.transaction do
      execute "insert into taggings " +
              "(tag_id, tagger_id, tagger_type, taggable_id, taggable_type, strength, created_on, metadata_type, metadata_id)" +
              "(select #{unwanted.id}, tagger_id, tagger_type, taggable_id, taggable_type, " + 
              "1, created_on, metadata_type, metadata_id from taggings " +
              "where tag_id = #{interesting.id} and strength = 0 and deleted_at is null);"
      execute "update taggings set deleted_at = NOW() where tag_id = #{interesting.id} and strength = 0 and deleted_at is null;"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Unable to restore negative interesting taggings from unwanted'
  end
end
