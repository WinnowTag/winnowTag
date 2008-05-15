class DropFeedPublished < ActiveRecord::Migration
  def self.up
    remove_column :feeds, :published
  end

  def self.down
  end
end
