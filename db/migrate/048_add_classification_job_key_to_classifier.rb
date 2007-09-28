# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class AddClassificationJobKeyToClassifier < ActiveRecord::Migration
  def self.up
    add_column :bayes_classifiers, :jobkey, :string
  end

  def self.down
    remove_column :bayes_classifiers, :jobkey
  end
end
