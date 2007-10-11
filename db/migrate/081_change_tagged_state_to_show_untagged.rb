class ChangeTaggedStateToShowUntagged < ActiveRecord::Migration
  def self.up
    add_column :views, :show_untagged, :boolean
    remove_column :views, :tagged_state
  end

  def self.down
    add_column :views, :tagged_state, :string
    remove_column :views, :show_untagged
  end
end
