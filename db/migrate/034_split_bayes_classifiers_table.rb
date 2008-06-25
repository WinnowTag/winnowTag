# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class SplitBayesClassifiersTable < ActiveRecord::Migration
  def self.up
    create_table :classifier_datas do |t|
      t.column :bayes_classifier_id, :integer, :null => false
      t.column :data, :longtext
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    execute <<-END
      INSERT INTO classifier_datas
        (bayes_classifier_id, data)
        (SELECT id, data FROM bayes_classifiers);
    END
    
    add_index :classifier_datas, :bayes_classifier_id
    
    remove_column :bayes_classifiers, :data
  end

  def self.down
    execute "ALTER TABLE bayes_classifiers ADD data longtext;"
    
    execute <<-END
      UPDATE bayes_classifiers, classifier_datas
      SET
        bayes_classifiers.data = classifier_datas.data
      WHERE
        bayes_classifiers.id = classifier_datas.bayes_classifier_id;
    END
    
    drop_table :classifier_datas    
  end
end
