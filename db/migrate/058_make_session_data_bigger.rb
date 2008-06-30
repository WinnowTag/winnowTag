# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class MakeSessionDataBigger < ActiveRecord::Migration
  def self.up
    execute('alter table sessions change data data mediumtext;')
  end

  def self.down
    change_column(:sessions, :data, :text)
  end
end
