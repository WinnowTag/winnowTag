class CreateTagExclusions < ActiveRecord::Migration
  def self.up
    create_table :tag_exclusions do |t|
      t.integer :tag_id
      t.integer :user_id
    end
  end

  def self.down
    drop_table :tag_exclusions
  end
end
