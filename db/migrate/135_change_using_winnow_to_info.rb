# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class ChangeUsingWinnowToInfo < ActiveRecord::Migration
  def self.up
    Setting.update_all "name = 'Info'", "name = 'Using Winnow'"
  end

  def self.down
    Setting.update_all "name = 'Using Winnow'", "name = 'Info'"
  end
end
