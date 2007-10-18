# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class MigrateOldTagsToUserTags < ActiveRecord::Migration
  class OldTag < ActiveRecord::Base
  end

  class Tag < ActiveRecord::Base
    belongs_to :user
  end

  class Tagging < ActiveRecord::Base
    belongs_to :tagger, :polymorphic => true
  end

  class User < ActiveRecord::Base
    has_many :taggings, :as => :tagger
  end
  
  class TagPublication < ActiveRecord::Base
  end
  
  def self.up
    Tag.transaction do
      User.find(:all).each do |user|
        find_old_tags_for(user).each do |old_tag|
          say "Updating #{old_tag.name} for #{user.login}"
          new_tag = Tag.create(:name => old_tag.name, :user => user)
          
          # check if this tag is published
          if pub = TagPublication.find(:first, :conditions => ['tag_id = ? and publisher_id = ?', old_tag.id, user.id])
            new_tag.update_attributes!(:comment => pub.comment, :public => true)
          end
          
          execute <<-END
            update taggings
              set tag_id = #{new_tag.id}
              where tag_id = #{old_tag.id}
                and (tagger_id = #{user.id} and tagger_type = 'User'
                  or tagger_id = #{classifier_id(user)} and tagger_type = 'BayesClassifier')
          END
        end
      end
      
      drop_table :old_tags
    end
  end

  # This is Irreversible mainly because I can't see any reason to make it reversible
  def self.down
    raise IrreversibleMigration
  end
  
  def self.find_old_tags_for(user)
    OldTag.find_by_sql("select * from old_tags where id in (" + 
                            "select tag_id from taggings where " + 
                            " tagger_id = #{user.id} and tagger_type = 'User')")
  end
  
  def self.classifier_id(user)
    BayesClassifier.find(:first, :conditions => ['tagger_id = ? and tagger_type = ?', user.id, 'User']).id    
  end
end
