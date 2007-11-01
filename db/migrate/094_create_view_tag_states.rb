class CreateViewTagStates < ActiveRecord::Migration
  def self.up
    create_table :view_tag_states do |t|
      t.column :view_id, :integer
      t.column :state, :string
      t.column :tag_id, :integer
    end
  end

  def self.down
    drop_table :view_tag_states
  end
end
