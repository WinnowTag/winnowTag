# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class ChangeUsingWinnowToInfo < ActiveRecord::Migration
  def self.up
    Setting.update_all "name = 'Info'", "name = 'Using Winnow'"
  end

  def self.down
    Setting.update_all "name = 'Using Winnow'", "name = 'Info'"
  end
end
