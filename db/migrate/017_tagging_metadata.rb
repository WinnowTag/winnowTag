class TaggingMetadata < ActiveRecord::Migration
  def self.up
    add_column "taggings", "metadata_type", :string, :null => true
    add_column "taggings", "metadata_id", :integer, :null => true
  end

  def self.down
    remove_column "taggings", "metadata_type"
    remove_column "taggings", "metadata_id"
  end
end
