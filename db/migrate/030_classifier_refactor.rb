# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ClassifierRefactor < ActiveRecord::Migration
  class Classifier < ActiveRecord::Base; end
  # We discovered, through classifier testing, that the
  # best mechanism for classifiers is to associate one with
  # a user and all the users tags. The structure we had before
  # that allowed a classifier to be associated with more
  # that one user and tag was extraneous and introduced 
  # unneccessay complexity.
  #
  # So here we get rid of each of the habtm relationships
  # and also the single table inheritance and go with
  # a simple one classifier <-> one user model for now.
  def self.up
    Classifier.delete_all
    drop_table :classifiers_users
    drop_table :classifiers_tags
    rename_table :classifiers, :bayes_classifiers
    
    remove_column :bayes_classifiers, :type
    add_column :bayes_classifiers, :user_id, :integer
    
    # We also add a column to the taggings table that defines
    # which user the tagging 'belongs' to regardless of who
    # created the tagging.
    add_column :taggings, :user_id, :integer
    
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
