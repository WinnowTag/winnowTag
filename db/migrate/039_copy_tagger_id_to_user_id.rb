# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class CopyTaggerIdToUserId < ActiveRecord::Migration
  def self.up
    execute "UPDATE taggings SET user_id = tagger_id WHERE tagger_type = 'User';"
  end

  def self.down
  end
end
