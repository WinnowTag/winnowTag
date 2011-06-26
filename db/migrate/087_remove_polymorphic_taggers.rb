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

class RemovePolymorphicTaggers < ActiveRecord::Migration
  class BayesClassifier < ActiveRecord::Base; end

  def self.up
    Tagging.transaction do
      execute "update taggings set user_id = tagger_id where tagger_type = 'User';"
    
      BayesClassifier.find(:all).each do |c|
        execute "update taggings " +
                  "set user_id = #{c.tagger_id}, " +
                      "classifier_tagging = 1 "    +
                  "where tagger_type = 'BayesClassifier' " +
                      "and tagger_id = #{c.id};"
      end
      
      remove_column :taggings, :tagger_type
      remove_column :taggings, :tagger_id
    end
  end

  def self.down
    # Nothing
  end
end
