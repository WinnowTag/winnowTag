# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ChangeTagsShowInSidebarFromNullToFalse < ActiveRecord::Migration
  def self.up
    Tag.update_all("show_in_sidebar = 0", "show_in_sidebar IS NULL")
  end

  def self.down
    # This was because of a bug in the codebase, it should never be reverted back to the buggy way
  end
end
