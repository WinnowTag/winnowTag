# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveCustomCharacterSetFromTagsName < ActiveRecord::Migration
  def self.up
    execute "alter table tags modify name varchar(255);"
  end

  def self.down
    execute "alter table tags modify name varchar(255) character set latin1 collate latin1_general_cs;"
  end
end
