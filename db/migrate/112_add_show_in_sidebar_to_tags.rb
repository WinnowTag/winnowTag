class AddShowInSidebarToTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :show_in_sidebar, :boolean, :default => true
  end

  def self.down
    remove_column :tags, :show_in_sidebar
  end
end
