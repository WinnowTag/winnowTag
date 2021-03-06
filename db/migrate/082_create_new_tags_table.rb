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

class CreateNewTagsTable < ActiveRecord::Migration
  def self.up
    rename_table :tags, :old_tags
    
    create_table :tags do |t|
      t.column :name, :string, :null => false
      t.column :user_id, :integer, :null => false
      t.column :public, :boolean
      t.column :comment, :text
      t.column :bias, :float
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    # Make name case sensitive
    execute "ALTER TABLE `tags` MODIFY COLUMN `name` VARCHAR(255)" +
              " CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL;"
    add_index :tags, [:user_id, :name], :unique => true
  end

  def self.down
    drop_table :tags
    rename_table :old_tags, :tags
  end
end
