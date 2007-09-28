# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

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
    
    say_with_time("Generating Random Background") do
      RandomBackground.generate
    end
  end

  def self.down
    drop_table :random_backgrounds
  end
end
