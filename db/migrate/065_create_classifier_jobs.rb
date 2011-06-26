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

class CreateClassifierJobs < ActiveRecord::Migration
  def self.up
    create_table :classifier_jobs do |t|
      t.column :bayes_classifier_id, :integer
      t.column :jobkey, :string
      t.column :progress, :integer, :default => 0
      t.column :progress_title, :string, :default => "Starting Classifier"
      t.column :progress_message, :text
      t.column :error_message, :text
      t.column :complete, :boolean, :default => false
      t.column :failed, :boolean, :default => false
      t.column :created_on, :datetime
      t.column :updated_on, :datetime
    end
    
    remove_column :bayes_classifiers, :jobkey
  end

  def self.down
    add_column :bayes_classifiers, :jobkey, :string
    drop_table :classifier_jobs
  end
end
