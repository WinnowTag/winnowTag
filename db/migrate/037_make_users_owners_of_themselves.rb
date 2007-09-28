class MakeUsersOwnersOfThemselves < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.has_role('owner', user)
    end
  end

  def self.down
  end
end
