# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateTokens < ActiveRecord::Migration
  def self.up
    create_table :tokens do |t|
      t.column :token, :string, :null => false
    end
    
    say 'Converting collation to case sensitive.'
    execute "ALTER TABLE `tokens` MODIFY COLUMN `token` VARCHAR(255)" +
              " CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL;"
              
    add_index :tokens, [:token], :unique => true
  end

  def self.down
    drop_table :tokens
  end
end
