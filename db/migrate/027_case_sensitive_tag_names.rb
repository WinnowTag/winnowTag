# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class CaseSensitiveTagNames < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.configurations[RAILS_ENV]['adapter'] = 'mysql'
      say 'Converting collation to case sensitive.'
      execute "ALTER TABLE `tags` MODIFY COLUMN `name` VARCHAR(255)" +
                " CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL;"
    else
      say 'Nothing needed to be done'
    end
  end

  def self.down
    if ActiveRecord::Base.configurations[RAILS_ENV]['adapter'] = 'mysql'
      execute "ALTER TABLE `tags` MODIFY COLUMN `name` VARCHAR(255)" +
                " CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL;"
    end
  end
end
