# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
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
