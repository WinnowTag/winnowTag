class AddSubjectAndBodyToInvites < ActiveRecord::Migration
  def self.up
    add_column :invites, :subject, :string
    add_column :invites, :body, :text
  end

  def self.down
    remove_column :invites, :body
    remove_column :invites, :subject
  end
end
