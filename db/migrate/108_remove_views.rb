class RemoveViews < ActiveRecord::Migration
  def self.up
    drop_table :views
    drop_table :view_tag_states
    drop_table :view_feed_states
  end

  def self.down
    create_table :views do |t|
      t.boolean :show_untagged, :default, :tag_inspect_mode
      t.string :name, :state, :text_filter
      t.integer :user_id
    end
    
    create_table :view_tag_states do |t|
      t.integer :view_id, :tag_id
      t.string :state
    end

    create_table :view_feed_states do |t|
      t.integer :view_id, :feed_id
      t.string :state
    end
  end
end
