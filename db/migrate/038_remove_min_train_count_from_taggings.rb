class RemoveMinTrainCountFromTaggings < ActiveRecord::Migration
  def self.up
    remove_column :taggings, :train_count
  end

  def self.down
    add_column :taggings, :train_count, :integer
  end
end
