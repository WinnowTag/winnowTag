class AddTaggedStateToView < ActiveRecord::Migration
  def self.up
    add_column :views, :tagged_state, :string
  end

  def self.down
    remove_column :views, :tagged_state
  end
end
