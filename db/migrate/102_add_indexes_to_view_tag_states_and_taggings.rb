class AddIndexesToViewTagStatesAndTaggings < ActiveRecord::Migration
  def self.up
    add_index :view_tag_states, :tag_id
    add_index :taggings, [:tag_id, :classifier_tagging, :strength]
    add_index :taggings, [:tag_id, :classifier_tagging]
    add_index :taggings, [:tag_id, :created_on]
  end

  def self.down
    remove_index :view_tag_states, :tag_id
    remove_index :taggings, [:tag_id, :classifier_tagging, :strength]
    remove_index :taggings, [:tag_id, :classifier_tagging]
    remove_index :taggings, [:tag_id, :created_on]
  end
end
