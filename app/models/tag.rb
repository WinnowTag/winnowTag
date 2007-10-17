# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

def Tag(user, tag)
  if tag.nil? || tag.is_a?(Tag) 
    tag
  else
    Tag.find_or_create_by_user_id_and_name(user.id, tag)    
  end
end

# Tag is a simple word used to tag an item. Every Tagging belongs to a Tag.
# 
# == Schema Information
# Schema version: 57
#
# Table name: tags
#
#  id   :integer(11)   not null, primary key
#  name :string(255)   
#

class Tag < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  
  has_many :taggings, :dependent => :delete_all
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true]
  belongs_to :user
  validates_uniqueness_of :name, :scope => :user_id
  validates_presence_of :name
  
  # Returns a suitable label for the classification UI display.
  def classification_label
    truncate(self.name, 15)
  end
  
  # Returns JSON representation of the tag.
  def to_json
    self.name.to_json
  end
  
  # Gets a string representation of the tag.
  def to_s
    self.name
  end
  
  # Gets a parameter representation of the tag.
  def to_param
    self.name
  end
  
  def inspect
    "<Tag name=#{name}, user=#{user.login}>"
  end
  
  # Provides the natural ordering of tags and their case-insensitive lexical ordering.
  def <=>(other)
    if other.is_a? Tag
      self.name.downcase <=> other.name.downcase
    else
      raise ArgumentError, "Cannot compare Tag to #{other.class}"
    end
  end
  
  def last_used_by(tagger)
    if tagging = tagger.taggings.find(:first, :conditions => ['tag_id = ?', self.id], :order => 'created_on DESC')
      tagging.created_on
    end
  end
  
  def copy(to)
    if self == to 
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    if self != to and to.taggings.size > 0
      raise ArgumentError, "Target tagger already has a #{to.name} tag"
    end
    
    self.manual_taggings.each do |tagging|
      to.user.taggings.create(:tag => to, :feed_item_id => tagging.feed_item_id, :strength => tagging.strength)
    end
  end
  
  def merge(to)
    if self == to 
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    count = 0
    self.manual_taggings.each do |tagging|
      unless to.manual_taggings.exists?(['feed_item_id = ?', tagging.feed_item_id])
        to.user.taggings.create(:tag => to, :feed_item_id => tagging.feed_item_id, :strength => tagging.strength)
        tagging.destroy
        count += 1
      end
    end
    
    count
  end
  
  def self.find_all_public_with_count
    find(:all, 
       :select => 'tags.*, ' <<
                  'COUNT(IF(classifier_tagging = 0 AND taggings.strength = 1, 1, NULL)) AS count, ' <<
                  'COUNT(IF(classifier_tagging = 0 AND taggings.strength = 0, 1, NULL)) AS negative_count, ' <<
                  'COUNT(IF(classifier_tagging = 1 AND taggings.strength >= 0.9, 1, NULL)) AS classifier_count',
       :joins => "LEFT JOIN taggings ON tags.id = taggings.tag_id",
       :conditions => ["tags.public = ?", true]
       :group => 'tags.id',
       :order => 'tags.name ASC')
  end
end
