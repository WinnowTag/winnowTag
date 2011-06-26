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
