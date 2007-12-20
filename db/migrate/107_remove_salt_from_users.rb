class RemoveSaltFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :salt
    change_column :users, :crypted_password, :string, :limit => 255
    User.update_all "crypted_password = NULL"
  end

  def self.down
    change_column :users, :crypted_password, :string, :limit => 40
    add_column :users, :salt, :string
  end
end
