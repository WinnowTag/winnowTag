# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.

# Refactors the feeds table to store XML data in a separate table.
class RefactorFeedsTable < ActiveRecord::Migration
  def self.up
    create_table :feed_xml_datas do |t|
      t.column :xml_data, :longtext
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    execute <<-END_SQL
      INSERT 
        INTO feed_xml_datas (id, xml_data, created_on, updated_on)
        SELECT id, last_xml_data, NOW(), NOW() from feeds;
    END_SQL
    
    remove_column :feeds, :last_xml_data
  end

  def self.down
    add_column :feeds, :last_xml_data, :longtext 
    drop_table :feed_xml_datas
  end
end
