class AddActiveColumnToSeeds < ActiveRecord::Migration
  def self.up
    add_column "seeds", "active", :boolean, :default => true
  end

  def self.down
    remove_column "seeds", "active"
  end
end
