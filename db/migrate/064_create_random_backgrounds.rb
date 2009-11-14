# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class CreateRandomBackgrounds < ActiveRecord::Migration
  def self.up
    # Rails doesn't let me have non-autoincrementing PK
    execute <<-END
             CREATE TABLE `random_backgrounds` (
               `feed_item_id` int(11) NOT NULL,
               `created_on` timestamp NOT NULL,
               PRIMARY KEY  (`feed_item_id`)
             ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
           END
    
    say("Generating Random Background (disabled)")
  end

  def self.down
    drop_table :random_backgrounds
  end
end
