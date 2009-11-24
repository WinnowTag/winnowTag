# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateXmlDataSizeColumn < ActiveRecord::Migration
  def self.up
    add_column :feed_items, :xml_data_size, :integer
    say "Calculating xml data size for each feed item, this could take some time..."
    execute 'UPDATE feed_items set xml_data_size = CHAR_LENGTH(xml_data);'
  end

  def self.down
    remove_column :feed_items, :xml_data_size
  end
end
