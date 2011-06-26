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

class AddPerTagBiasToBayesClassifier < ActiveRecord::Migration
  def self.up
    rename_column :bayes_classifiers, :bias, :default_bias
    rename_column :classifier_executions, :bias, :default_bias
    
    add_column :bayes_classifiers, :bias, :text
    add_column :classifier_executions, :bias, :text

    change_column_default(:bayes_classifiers, :default_bias, 1.0)
    change_column_default(:classifier_executions, :default_bias, 1.0)
  end

  def self.down
    remove_column :bayes_classifiers, :bias
    remove_column :classifier_executions, :bias

    rename_column :bayes_classifiers, :default_bias, :bias
    rename_column :classifier_executions, :default_bias, :bias

    change_column_default(:bayes_classifiers, :bias, 1.0)
    change_column_default(:classifier_executions, :bias, 1.0)
  end
end
