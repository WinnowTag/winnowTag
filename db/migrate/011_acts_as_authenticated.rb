class ActsAsAuthenticated < ActiveRecord::Migration
  def self.up
    remove_column "users", "role"
    remove_column "users", "deleted"
    remove_column "users", "token_expiry"
    remove_column "users", "verified"
    rename_column "users", "delete_after", "deleted_at"
    rename_column "users", "salted_password", "crypted_password"
    rename_column "users", "security_token", "activation_code"
    add_column "users", "activated_at", :datetime
    add_column "users", "remember_token", :string
    add_column "users", "remember_token_expires_at", :datetime
  end

  def self.down
    remove_column "users", "remember_token"
    remove_column "users", "remember_token_expires_at"
    remove_column "users", "activated_at"
    rename_column "users", "activation_code", "security_token"
    rename_column "users", "deleted_at", "delete_after"
    rename_column "users", "crypted_password", "salted_password"
    add_column "users", "role", :string
    add_column "users", "deleted", :integer
    add_column "users", "token_expiry", :datetime
    add_column "users", "verified", :integer
    
    # verify all
    User.find(:all).each do |u|
      u.verified = true
      u.save
    end
  end
  
  class User < ActiveRecord::Base; end
end
