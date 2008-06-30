# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
