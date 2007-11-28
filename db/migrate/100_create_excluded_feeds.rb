class CreateExcludedFeeds < ActiveRecord::Migration
  def self.up
    create_table :excluded_feeds do |t|
      t.column :feed_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :excluded_feeds
  end
end
