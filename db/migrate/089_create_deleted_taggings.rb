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

class CreateDeletedTaggings < ActiveRecord::Migration
  def self.up
    # Why don't people like using Raw SQL?
    
    execute "create table deleted_taggings like taggings;"
    execute "insert into deleted_taggings select * from taggings where deleted_at is not null;"
    execute "delete from taggings where deleted_at is not null;"
    remove_column :taggings, :deleted_at
    execute "ALTER IGNORE TABLE deleted_taggings add constraint dt_tag foreign key (tag_id) " +
             "references tags(id) on delete cascade;"
    execute "ALTER IGNORE TABLE deleted_taggings add constraint dt_user foreign key (user_id) " +
              "references users(id) on delete cascade;"
  end

  def self.down
    add_column :taggings, :deleted_at, :datetime
    execute "insert into taggings select * from deleted_taggings;"
    drop_table :deleted_taggings
  end
end
