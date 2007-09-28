class AddCutoffParameterToClassifierExecution < ActiveRecord::Migration
  def self.up
    add_column :classifier_executions, :cutoff, :float
  end

  def self.down
    remove_column :classifier_executions, :cutoff
  end
end
