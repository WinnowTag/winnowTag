class CreateInvites < ActiveRecord::Migration
  def self.up
    create_table :invites do |t|
      t.string :email
      t.string :code
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :invites
  end
end
