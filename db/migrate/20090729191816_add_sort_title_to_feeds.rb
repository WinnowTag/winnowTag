# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AddSortTitleToFeeds < ActiveRecord::Migration
  class Feed < ActiveRecord::Base; end
  
  def self.up
    add_column :feeds, :sort_title, :string

    Feed.update_all("sort_title = TRIM(LEADING 'a ' from TRIM(LEADING 'an ' from TRIM(LEADING 'the ' from LCASE(IFNULL(title, '')))))")
  end

  def self.down
    remove_column :feeds, :sort_title
  end
end
