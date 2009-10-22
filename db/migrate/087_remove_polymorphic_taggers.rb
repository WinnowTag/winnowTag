# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
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
