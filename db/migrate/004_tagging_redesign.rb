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


# This migration marks the beginning of the use of the new tagging design.
# Documentation for this tagging design can be found at 
# http://trac.winnow.peerworks.org/wiki/TaggingDesign
#
# This is an irreversible migration that will destroy the old
# tagging tables and any tag data in them.
class TaggingRedesign < ActiveRecord::Migration
  def self.up
    # start by destroying old tags and tagging tables
    drop_table "tags"
    drop_table "tags_seed_items"
    
    create_table "tags" do |t|
        t.column "name", :string
    end
    
    create_table "taggings" do |t|
        t.column "taggable_type", :string
        t.column "taggable_id", :integer
        t.column "tagger_type", :string
        t.column "tagger_id", :integer
        t.column "created_on", :datetime
        t.column "tag_id", :integer
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
