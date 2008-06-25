# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AddedFeedsSortTitle < ActiveRecord::Migration
  def self.up
    add_column :feeds, :sort_title, :string
    
    execute "update feeds set sort_title = TRIM(LEADING 'an ' from TRIM(LEADING 'a ' from TRIM(LEADING 'the ' from LCASE(title))));"
    
    add_index :feeds, :sort_title
  end

  def self.down
    remove_column :feeds, :sort_title
    remove_index :feeds, :sort_title
  end
end
