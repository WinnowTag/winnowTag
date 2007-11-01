class CreateViewFeedStates < ActiveRecord::Migration
  def self.up
    create_table :view_feed_states do |t|
      t.column :view_id, :integer
      t.column :state, :string
      t.column :feed_id, :integer
    end
  end

  def self.down
    drop_table :view_feed_states
  end
end
