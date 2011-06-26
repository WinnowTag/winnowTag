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

class RemoveOldClassifierOptions < ActiveRecord::Migration
  def self.up
    remove_column :bayes_classifiers, :min_token_count
    remove_column :bayes_classifiers, :min_train_count
    remove_column :bayes_classifiers, :min_prob_strength
    remove_column :bayes_classifiers, :unknown_word_strength
    remove_column :bayes_classifiers, :unknown_word_prob
    remove_column :bayes_classifiers, :max_discriminators
    remove_column :bayes_classifiers, :foreground_weights
    remove_column :bayes_classifiers, :background_weights
    
    remove_column :classifier_executions, :min_token_count
    remove_column :classifier_executions, :min_train_count
    remove_column :classifier_executions, :min_prob_strength
    remove_column :classifier_executions, :unknown_word_strength
    remove_column :classifier_executions, :unknown_word_prob
    remove_column :classifier_executions, :max_discriminators
    remove_column :classifier_executions, :foreground_weights
    remove_column :classifier_executions, :background_weights
  end

  def self.down
    add_column :bayes_classifiers, :min_token_count, :integer, :default => 50
    add_column :bayes_classifiers, :min_train_count, :integer, :default => 0
    add_column :bayes_classifiers, :min_prob_strength, :float, :default => 0.1
    add_column :bayes_classifiers, :unknown_word_prob, :float, :default => 0.5
    add_column :bayes_classifiers, :unknown_word_strength, :float, :default => 0.45
    add_column :bayes_classifiers, :max_discriminators, :integer, :default => 150  
    add_column :bayes_classifiers, :foreground_weights, :text
    add_column :bayes_classifiers, :background_weights, :text
    
    add_column :classifier_executions, :min_token_count, :integer, :default => 50
    add_column :classifier_executions, :min_train_count, :integer, :default => 0
    add_column :classifier_executions, :min_prob_strength, :float, :default => 0.1
    add_column :classifier_executions, :unknown_word_prob, :float, :default => 0.5
    add_column :classifier_executions, :unknown_word_strength, :float, :default => 0.45
    add_column :classifier_executions, :max_discriminators, :integer, :default => 150  
    add_column :classifier_executions, :foreground_weights, :text
    add_column :classifier_executions, :background_weights, :text
  end
end
