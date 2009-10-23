# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class RemoveRubyClassifierTables < ActiveRecord::Migration
  def self.up
    drop_table :bayes_classifiers
    drop_table :classifier_executions
    drop_table :classifier_datas    
  end

  def self.down
    raise IrreversibleMigration
  end
end
