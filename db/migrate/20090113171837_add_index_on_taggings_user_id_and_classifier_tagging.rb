class AddIndexOnTaggingsUserIdAndClassifierTagging < ActiveRecord::Migration
  def self.up
    add_index :taggings, [:user_id, :classifier_tagging]
  end

  def self.down
    remove_index :taggings, [:user_id, :classifier_tagging]
  end
end
