class AddPrototypeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :prototype, :boolean
  end

  def self.down
    remove_column :users, :prototype
  end
end
