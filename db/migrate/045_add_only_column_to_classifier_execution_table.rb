# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddOnlyColumnToClassifierExecutionTable < ActiveRecord::Migration
  def self.up
    add_column :classifier_executions, :only, :text
  end

  def self.down
    remove_column :classifier_executions, :only
  end
end
