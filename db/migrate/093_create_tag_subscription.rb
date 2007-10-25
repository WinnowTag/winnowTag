class CreateTagSubscription < ActiveRecord::Migration
  def self.up
    create_table :tag_subscriptions do |t|
      t.column :tag_id, :integer
      t.column :user_id, :integer
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :tag_subscriptions
  end
end
