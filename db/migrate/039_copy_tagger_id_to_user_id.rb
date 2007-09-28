class CopyTaggerIdToUserId < ActiveRecord::Migration
  def self.up
    execute "UPDATE taggings SET user_id = tagger_id WHERE tagger_type = 'User';"
  end

  def self.down
  end
end
