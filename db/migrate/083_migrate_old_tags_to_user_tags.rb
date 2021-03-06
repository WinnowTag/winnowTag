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

class MigrateOldTagsToUserTags < ActiveRecord::Migration
  class OldTag < ActiveRecord::Base
  end

  class Tagging < ActiveRecord::Base
    belongs_to :tagger, :polymorphic => true
  end

  class User < ActiveRecord::Base
    has_many :taggings, :as => :tagger
  end
  
  class TagPublication < ActiveRecord::Base
  end

  class Tag < ActiveRecord::Base
    belongs_to :user, :class_name => 'MigrateOldTagsToUserTags::User'
  end
  
  class BayesClassifier < ActiveRecord::Base
    belongs_to :user
  end
  
  def self.up
    Tag.transaction do
      execute "create temporary table temp_taggings like taggings;"

      User.find(:all).each do |user|
        find_old_tags_for(user).each do |old_tag|
          say "Updating #{old_tag.name} for #{user.login}"
          new_tag = Tag.create(:name => old_tag.name, :user => user)
          
          # check if this tag is published
          if pub = TagPublication.find(:first, :conditions => ['tag_id = ? and publisher_id = ?', old_tag.id, user.id])
            new_tag.update_attributes!(:comment => pub.comment, :public => true)
          end
          
          execute <<-END
            insert into temp_taggings
              ( tag_id,
 		taggable_type, taggable_id,
 		tagger_type, tagger_id,
		created_on,  deleted_at,
		metadata_type, metadata_id,
 		strength )
            select
	       #{new_tag.id},
 		taggable_type, taggable_id,
	 	tagger_type, tagger_id,
 		created_on,  deleted_at,
 		metadata_type, metadata_id,
 		strength
	      from taggings
              where tag_id = #{old_tag.id}
                and ((tagger_id = #{user.id} and tagger_type = 'User')
                  or (tagger_id = #{classifier_id(user)} and tagger_type = 'BayesClassifier'))
          END

	 say "#{ActiveRecord::Base.connection.connection.affected_rows} affected rows"
        end
      end

      execute "delete from taggings;"
      execute "insert into taggings select * from temp_taggings;"      
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
