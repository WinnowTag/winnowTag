# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Folder < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :feeds, :order => :title
  has_and_belongs_to_many :tags, :order => :name do
    def with_counts
      self.find(:all, :select => ['tags.*',
        '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
        '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
        '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count'
       ].join(",")
      )
    end
  end
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :user_id, :case_sensitive => false
  
  def self.remove_tag(user, tag_id)
    folders = user.folders
    folders.each do |folder|
      folder.tag_ids -= [tag_id.to_i]
    end
  end
  
  def self.remove_feed(user, feed_id)
    folders = user.folders
    folders.each do |folder|
      folder.feed_ids -= [feed_id.to_i]
    end
  end
end
