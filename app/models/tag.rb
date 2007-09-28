# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

def Tag(tag)
  tag.nil? ? tag : tag.is_a?(Tag) ? tag : Tag.find_or_create_by_name(tag)
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
  # Reserved as a special tag name that acts as a tag wildcard.
  TAGGED = '__tagged__' unless const_defined?(:TAGGED)
  # Contains a list of reserved tag names
  MAGIC_TAGS = [TAGGED] unless const_defined?(:MAGIC_TAGS)
  has_many :taggings
  validates_uniqueness_of :name
  validates_presence_of :name
    
  # Returns true if the name of this tag is TAGGED.
  #
  # This means that this tag can be interpreted as any tag used by the user.
  def tagged_filter?
    self.name == TAGGED
  end
  
  # Returns a suitable label for the classification UI display.
  #
  def classification_label
    if self.name == TAGGED
      "all"
    else
      truncate(self.name, 15)
    end
  end
  
  # Returns JSON representation of the tag.
  #
  # If the tag is TAGGED, it is interpreted as nil.
  def to_json
    if self.name == TAGGED
      nil.to_json
    else
      self.name.to_json
    end
  end
  
  # Gets a string representation of the tag.
  def to_s
    self.name
  end
  
  # Gets a parameter representation of the tag.
  def to_param
    self.name
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
end
