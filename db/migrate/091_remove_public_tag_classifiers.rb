# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class RemovePublicTagClassifiers < ActiveRecord::Migration
  def self.up
    execute "delete from bayes_classifiers where tagger_type <> 'User';"
    remove_column :bayes_classifiers, :tagger_type
    rename_column :bayes_classifiers, :tagger_id, :user_id
  end

  def self.down
    raise IrreversibleMigration
  end
end
