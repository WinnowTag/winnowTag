class AddSortNameToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :sort_name, :string

    Tag.find_each do |tag|
      tag.save!
    end
  end

  def self.down
    remove_column :tags, :sort_name
  end
end
