# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# A BulkTagging has two responsibilities:
#
#   * Firstly it creates bulk taggings based on some filter on behalf
#     of a tagger.
#   * Secondly it acts as metadata for the bulk tagging.
#
# If exclusive == true all other taggings on each item will be removed.
#
# == Schema Information
# Schema version: 57
#
# Table name: bulk_taggings
#
#  id           :integer(11)   not null, primary key
#  filter_type  :string(255)   
#  filter_value :string(255)   
#  created_on   :datetime      
#

class BulkTagging < ActiveRecord::Base
  acts_as_immutable
  attr_accessor :strength, :filter, :tag, :tagger, :tags, :exclusive
  validates_presence_of :filter, :tags, :tagger, :on => :create
  has_many :taggings, :as => :metadata
  FeedFilter = 'FeedFilter'
  before_validation :setup_tags_to_apply
  
  def self.destroy_for(filter, tagger, tag)
    if filter.is_a? Feed
      bulks = self.find(:all, :conditions => ['filter_type = ? and filter_value = ? and taggings.tag_id = ? and '+
                                  'taggings.tagger_type = ? and taggings.tagger_id = ?', 
                                  FeedFilter, filter.id, tag.id, tagger.class.to_s, tagger.id],
                              :include => :taggings)
      bulks.each do |bulk|
        bulk.taggings.each do |tagging|
          tagging.destroy
        end
      end
    end
  end
  
  def before_create
    if @filter.is_a? Feed
      self.filter_type = FeedFilter
      self.filter_value = @filter.id
      
      Tagging.transaction do
        @filter.feed_items.each do |item|
          self.tags.each do |tag, strength|
            create_tagging(item, tag, strength)
          end
        end
      end
    end
  end
  
  private
  def setup_tags_to_apply
    self.tags = if self.tags.is_a? Hash
      self.tags.inject({}) do |tag_hash, entry|
        tag, strength = entry
        if tag.is_a? Tag
          tag_hash[tag] = strength
        else
          tag_hash[Tag.find_or_create_by_name(tag)] = strength
        end
        tag_hash
      end
    elsif self.tags.is_a? Array
      self.tags.inject({}) do |tag_hash, tag_name|
        tag_hash[Tag.find_or_create_by_name(tag_name)] = 1
        tag_hash
      end
    elsif self.tag
      tag = self.tag.is_a?(Tag) ? self.tag : Tag.find_or_create_by_name(self.tag)
      {tag => (self.strength or 1)}
    else
      nil
    end
  end
  
  def create_tagging(taggable, tag, strength)
    if self.exclusive
      taggable.taggings.find_by_tagger(self.tagger).each {|tagging| tagging.destroy}
      self.taggings.create(:tagger => self.tagger, :tag => tag, :strength => strength, :taggable => taggable)
    else
      existing = Tagging.find(:first, :conditions => ["tagger_type = ? and tagger_id = ? " + 
                                      "and taggable_type = ? and taggable_id = ? and tag_id = ?",
                                      self.tagger.class.name, self.tagger.id, taggable.class.name, taggable.id, tag.id])
    
      if existing.nil? or existing.metadata_type == self.class.name.to_s
        existing.destroy unless existing.nil?
        self.taggings.create(:tagger => self.tagger, :tag => tag, :strength => strength, :taggable => taggable)
      end
    end
  end
end
