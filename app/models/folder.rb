# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Folder < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :user_id
  
  def feed_ids
    read_attribute(:feed_ids).to_s.split(",").map(&:to_i)
  end
  
  def tag_ids
    read_attribute(:tag_ids).to_s.split(",").map(&:to_i)
  end
  
  def feed_ids=(feed_ids)
    write_attribute(:feed_ids, feed_ids.map(&:to_s).uniq.join(","))
  end
  
  def tag_ids=(tag_ids)
    write_attribute(:tag_ids, tag_ids.map(&:to_s).uniq.join(","))
  end
  
  def feeds
    Feed.find_all_by_id(feed_ids, :order => :title)
  end
  
  def tags
    Tag.find_all_by_id(tag_ids, :order => :name)
  end

  def tags_with_counts
    Tag.find :all, 
      :select => ['tags.*',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
                  '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count'
                 ].join(","),
      :conditions => { :id => tag_ids },
      :order => :name
  end
  
  def add_tag!(tag_id)
    self.tag_ids = self.tag_ids + [tag_id.to_i]
    self.save!
  end
  
  def add_feed!(feed_id)
    self.feed_ids = self.feed_ids + [feed_id.to_i]
    self.save!
  end
  
  def remove_tag!(tag_id)
    self.tag_ids = self.tag_ids - [tag_id.to_i]
    self.save!
  end
  
  def remove_feed!(feed_id)
    self.feed_ids = self.feed_ids - [feed_id.to_i]
    self.save!
  end
  
  def self.remove_tag(user, tag_id)
    folders = user.folders
    folders.each do |folder|
      folder.remove_tag!(tag_id)
    end
  end
  
  def self.remove_feed(user, feed_id)
    folders = user.folders
    folders.each do |folder|
      folder.remove_feed!(feed_id)
    end
  end
end
