# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertSessionsToInnodb < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE sessions ENGINE=INNODB;"
  end

  def self.down
    execute "ALTER TABLE sessions ENGINE=MYISAM;"
  end
end
