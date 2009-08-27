class UpdateFeedsSortTitleToStripEverythingExceptLettersAndNumbers < ActiveRecord::Migration
  def self.up
    Feed.find_each do |feed|
      feed.save!
    end
  end

  def self.down
  end
end
