# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RefactorFeedItemsTable < ActiveRecord::Migration
  def self.up
    create_table :feed_item_xml_data do |t|
      t.column :xml_data, :longtext
      t.column :created_on, :datetime      
    end
    
    execute <<-END_SQL
      INSERT
        INTO feed_item_xml_data (id, xml_data, created_on)
        SELECT id, xml_data, NOW() from feed_items;
    END_SQL
    
    remove_column :feed_items, :xml_data
  end

  def self.down
    execute "alter table feed_items add column xml_data longtext;"
    execute <<-END_SQL
      UPDATE
        feed_items, feed_item_xml_data
      SET
        feed_items.xml_data = feed_item_xml_data.xml_data
      WHERE
        feed_items.id = feed_item_xml_data.id;
    END_SQL
    drop_table :feed_item_xml_data
  end
end
