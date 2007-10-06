# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# RenameTagging is an operation that can rename or merge
# a users taggings. The RenamingTagging also acts as metadata
# for the operation and is stored in the metadata for each newly
# created tag.
#
# This metadata functionality might be overkill, but we thought we
# might need it for later analysis, so we have it.
# 
# The act of renaming or merging is fairly automatic, you just need to create
# a RenameTagging instance and when it is saved the renaming will occur. Thsi will
# also automatically rename any taggings created by the users classifier.
#
# == Schema Information
# Schema version: 57
#
# Table name: rename_taggings
#
#  id             :integer(11)   not null, primary key
#  old_tag_id     :integer(11)   not null
#  new_tag_id     :integer(11)   not null
#  tagger_id      :integer(11)   not null
#  tagger_type    :string(255)   default(""), not null
#  number_renamed :integer(11)   default(0)
#  number_left    :integer(11)   default(0)
#  created_on     :datetime      not null
#

class RenameTagging < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  acts_as_immutable
  belongs_to :old_tag, :class_name => 'Tag', :foreign_key => 'old_tag_id'
  belongs_to :new_tag, :class_name => 'Tag', :foreign_key => 'new_tag_id'
  belongs_to :tagger, :polymorphic => true
  has_many :taggings, :as => :metadata
  validates_presence_of :old_tag, :new_tag, :tagger_id, :tagger_type, :on => :create
  validates_associated :old_tag, :new_tag, :on => :create
  validates_difference_between :old_tag, :new_tag
  after_create :rename_tags
  
  # Gets a message describing how many taggings were renamed or merged by this operation
  def message
    msg = "Renamed #{pluralize(self.number_renamed, 'tag')} from #{self.old_tag.name} to #{self.new_tag.name}."
    
    if self.number_left > 0 
      msg += " Left #{self.number_left} #{self.old_tag.name} tag untouched because #{self.new_tag.name} already exists on the item."
    end
    
    msg
  end
  
  protected
  def rename_tags # :nodoc:
    tagger.taggings.find_by_tag(old_tag).each do |tagging_to_rename|
      existing_tagging = tagger.taggings.find_by_tag(new_tag, :first, 
                              :conditions => ['taggings.taggable_id = ? and taggings.taggable_type = ?', 
                                              tagging_to_rename.taggable_id, tagging_to_rename.taggable_type])
      if existing_tagging.nil?
        self.taggings.create(:tag => self.new_tag, :tagger => self.tagger, 
                             :taggable => tagging_to_rename.taggable, 
                             :strength => tagging_to_rename.strength)
        tagging_to_rename.destroy
        self.number_renamed += 1
      else
        self.number_left += 1
      end
    end
    
    if self.tagger.respond_to?(:classifier)
      tagger.classifier.taggings.find_by_tag(old_tag).each do |tagging_to_rename|
        existing_tagging = tagger.classifier.taggings.find_by_tag(new_tag, :first, 
                                :conditions => ['taggings.taggable_id = ? and taggings.taggable_type = ?', 
                                                tagging_to_rename.taggable_id, tagging_to_rename.taggable_type])
        if existing_tagging.nil?
          self.taggings.create(:tag => self.new_tag, :tagger => self.tagger.classifier, 
                               :taggable => tagging_to_rename.taggable, 
                               :strength => tagging_to_rename.strength)
          self.number_renamed += 1
        end
        tagging_to_rename.destroy
      end
    end
  end
end
