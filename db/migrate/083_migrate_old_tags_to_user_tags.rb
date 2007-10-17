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
  end

  class Tagging < ActiveRecord::Base
    belongs_to :tagger, :polymorphic => true
  end

  class User < ActiveRecord::Base
    has_many :taggings, :as => :tagger
  end
  
  def self.up
    Tag.transaction do
      User.find(:all).each do |user|
        find_old_tags_for(user).each do |old_tag|
          new_tag = user.tags.create(:name => old_tag.name)
          execute <<-END
            update taggings
              set tag_id = #{new_tag.id}
              where tag_id = #{old_tag.id}
                and (tagger_id = #{user.id} and tagger_type = 'User'
                  or tagger_id = #{user.classifier.id} and tagger_type = 'BayesClassifier')
          END
        end
      end
      
      drop_table :old_tags
    end
  end

  # This is Irreversible mainly because I can't see any reason to make it reversible
  def self.down
    #raise IrreversibleMigration
  end
  
  def self.find_old_tags_for(user)
    OldTag.find(user.taggings.map(&:tag_id).uniq)
  end
end
