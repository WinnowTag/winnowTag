class TaggingActsAsParanoid < ActiveRecord::Migration
  def self.up
    add_column "taggings", "deleted_at", :datetime
  end

  def self.down
    remove_column "taggings", "deleted_at"
  end
end
