class CreateBulkTaggings < ActiveRecord::Migration
  def self.up
    create_table :bulk_taggings do |t|
      t.column :filter_type, :string
      t.column :filter_value, :string
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :bulk_taggings
  end
end
