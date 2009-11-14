# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddOnlyColumnToClassifierExecutionTable < ActiveRecord::Migration
  def self.up
    add_column :classifier_executions, :only, :text
  end

  def self.down
    remove_column :classifier_executions, :only
  end
end
