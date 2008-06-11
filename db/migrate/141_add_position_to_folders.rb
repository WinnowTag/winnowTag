class AddPositionToFolders < ActiveRecord::Migration
  def self.up
    add_column :folders, :position, :integer
  end

  def self.down
    remove_column :folders, :position
  end
end
