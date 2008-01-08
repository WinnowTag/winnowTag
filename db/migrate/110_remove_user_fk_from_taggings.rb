# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class RemoveUserFkFromTaggings < ActiveRecord::Migration
  def self.up
    execute "alter ignore table taggings drop foreign key taggings_ibfk_2"
  end

  def self.down
  end
end
