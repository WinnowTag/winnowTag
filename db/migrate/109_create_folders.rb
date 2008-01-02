class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders do |t|
      t.string :name
      t.integer :user_id
      t.string :tag_ids
      t.string :feed_ids

      t.timestamps
    end
  end

  def self.down
    drop_table :folders
  end
end
