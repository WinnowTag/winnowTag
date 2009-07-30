class RemoveCustomCharacterSetFromTagsName < ActiveRecord::Migration
  def self.up
    execute "alter table tags modify name varchar(255);"
  end

  def self.down
    execute "alter table tags modify name varchar(255) character set latin1 collate latin1_general_cs;"
  end
end
