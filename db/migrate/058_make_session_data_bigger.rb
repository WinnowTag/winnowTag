# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class MakeSessionDataBigger < ActiveRecord::Migration
  def self.up
    execute('alter table sessions change data data mediumtext;')
  end

  def self.down
    change_column(:sessions, :data, :text)
  end
end
