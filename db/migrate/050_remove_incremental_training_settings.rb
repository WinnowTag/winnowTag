# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class RemoveIncrementalTrainingSettings < ActiveRecord::Migration
  def self.up
    rename_column :bayes_classifiers, :classification_cutoff, :positive_cutoff
    rename_column :bayes_classifiers, :incremental_training_cutoff, :insertion_cutoff
    remove_column :bayes_classifiers, :incremental_training_limit
    add_column :bayes_classifiers, :borderline_threshold, :float, :default => 0.02
    
    rename_column :classifier_executions, :classification_cutoff, :positive_cutoff
    rename_column :classifier_executions, :incremental_training_cutoff, :insertion_cutoff
    remove_column :classifier_executions, :classification_mode
    
    change_column_default(:bayes_classifiers, :positive_cutoff, 0.9)
    change_column_default(:bayes_classifiers, :insertion_cutoff, 0.8)
  end

  def self.down
    rename_column :bayes_classifiers, :positive_cutoff, :classification_cutoff
    rename_column :bayes_classifiers, :insertion_cutoff, :incremental_training_cutoff
    add_column :bayes_classifiers, :incremental_training_limit, :integer, :default => 1000
    remove_column :bayes_classifiers, :borderline_threshold
    
    rename_column :classifier_executions, :positive_cutoff, :classification_cutoff
    rename_column :classifier_executions, :insertion_cutoff, :incremental_training_cutoff
    add_column :classifier_executions, :classification_mode, :string, :default => 'classification'
  end
end
