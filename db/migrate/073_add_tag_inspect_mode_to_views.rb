class AddTagInspectModeToViews < ActiveRecord::Migration
  def self.up
    add_column :views, :tag_inspect_mode, :boolean
  end

  def self.down
    remove_column :views, :tag_inspect_mode
  end
end
