# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ChangeTokenMappingToUseALog < ActiveRecord::Migration
  def self.up
    say "extracting tokens to token log file"
    execute("select id, token into outfile '/tmp/tokens.log' fields terminated by ',' from tokens order by id;")
    say "You now need to manually move /tmp/tokens.log to the log directory and make it R/W for the Winnow user. Sorry."
    drop_table :tokens    
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
