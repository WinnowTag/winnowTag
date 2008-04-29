class RemoveMetadataInformationFromTaggings < ActiveRecord::Migration
  def self.up
    remove_column :taggings, :metadata_id
    remove_column :taggings, :metadata_type
  end

  def self.down
    add_column :taggings, :metadata_id, :integer
    add_column :taggings, :metadata_type, :string
  end
end
