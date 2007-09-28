class IncreaseClassifierDataColumnSize < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE `classifiers` MODIFY COLUMN `data` LONGTEXT;'
  end

  def self.down
  end
end
