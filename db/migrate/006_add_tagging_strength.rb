class AddTaggingStrength < ActiveRecord::Migration
  def self.up
    add_column "taggings", "strength", :float, :default => 1.0
  end

  def self.down
    remove_column "taggings", "strength"
  end
end
