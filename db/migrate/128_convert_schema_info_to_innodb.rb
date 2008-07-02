# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ConvertSchemaInfoToInnodb < ActiveRecord::Migration
  def self.up
    # Handled by Rails 2.1
    #execute "ALTER TABLE schema_info ENGINE=INNODB;"
  end

  def self.down
    #execute "ALTER TABLE schema_info ENGINE=MYISAM;"
  end
end
