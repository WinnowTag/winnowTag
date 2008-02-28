class AddHearAndUseToInvites < ActiveRecord::Migration
  def self.up
    add_column :invites, :hear, :text
    add_column :invites, :use, :text
  end

  def self.down
    remove_column :invites, :use
    remove_column :invites, :hear
  end
end
