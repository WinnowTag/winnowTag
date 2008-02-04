# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AtomizeFeeds < ActiveRecord::Migration
  def self.up
    # remove auto-increment from feeds
    execute "alter table feeds modify column id integer not null;"   
    remove_column :feeds, :is_duplicate
    remove_column :feeds, :active
    rename_column :feeds, :link, :alternate
    rename_column :feeds, :url, :via
    add_column :feeds, :collector_link, :string
          
    # add atom timestamp columns, these are independent from the internal updated_on and created_on columns
    add_column :feeds, :updated, :datetime
    add_column :feeds, :published, :datetime
    execute "update feeds set updated = updated_on and published = created_on;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
