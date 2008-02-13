# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# A Tagging represents the relationship between a Tag, a Tagger and
# a Taggable. It is the core class within Winnow's tagging infra-structure.
# A Tagging can be thought of as the application of a Tag to a Taggable
# by a Tagger.
#
# == Design
#
# For a lengthy description of how the tagging design came to be see 
# http://trac.winnow.peerworks.org/wiki/WinnowTaggingDesign although
# this is possibly a bit out-of-date and as always the code is the most
# current documentation.
#
# This diagram shows the current design from the point of view of relationships
# between classes.
#
# link:../tagging_design.png
# 
# As you can see, for better or worse, we make use of polymorphic associations
# to create the abstract Tagger and Taggable classes. This allows any class to be
# tagged or to tag something, i.e. be a tagger. The polymorphism is only currently 
# used for the tagger association since we have BayesClassifier and User both acting
# as Taggers. While the model does support creating many different types of Taggables,
# Winnow only currently supports tagging FeedItem instances.
# 
# == Immutability and Destruction
#
# A Tagging is immutable, i.e. once created it can never be changed.
#
# A Tagging is also never really deleted, instead, when it is destroyed it's deleted_at
# field is set to Time.now. This is necessary since when a Tagging is destroyed, the classifier
# needs to untrain it (which is done in a separate process before the next classification),
# however it also needs to know the details of the Tagging in order to untrain it.
#
# At some point we may want to have some method that sweeps the taggings table and clears out
# old taggings, but we haven't needed that yet.
#
# == Tagging Strength
#
# A Tagging has a strength attribute that defines its positivity. The meaning of this attribute
# is dependant on the Tagger, for example with a User tagger a strength of 1 is a positive tagging
# and a strength of 0 is a negative tagging. With a classifier the strength is the probability that
# the classifier would assign the tag and a probability over the classifier's positive_cutoff 
# should be considered positive.
#
# == Metadata
# 
# A Tagging allows additional metadata to be associated with it. This is also a polymorphic association,
# metadata. 
#
# See ClassifierExecution and RenameTagging for examples of classes that can be used as tagging metdata.
#
# == Schema Information
# Schema version: 57
#
# Table name: taggings
#
#  id            :integer(11)   not null, primary key
#  taggable_type :string(255)   
#  taggable_id   :integer(11)   
#  tagger_type   :string(255)   
#  tagger_id     :integer(11)   
#  created_on    :datetime      
#  tag_id        :integer(11)   
#  strength      :float         default(1.0)
#  deleted_at    :datetime      
#  metadata_type :string(255)   
#  metadata_id   :integer(11)   
#

class Tagging < ActiveRecord::Base
  acts_as_immutable
  belongs_to :tag
  belongs_to :feed_item
  belongs_to :user
  belongs_to :metadata, :polymorphic => true
  
  validates_presence_of [:tag, :user, :feed_item]
  validates_numericality_of :strength
  validates_inclusion_of :strength, :in => 0..1
  validates_associated :tag
  
  before_create :remove_preexisting_tagging
  after_create :update_tag_timestamp
  before_destroy :update_tag_timestamp
  after_destroy do |tagging|
    DeletedTagging.create(tagging.attributes.merge(:deleted_at => Time.now.utc))
  end
  
  # Returns true if this tagging is positive based on the definition
  # of positive defined by the Tagger.
  #
  def positive?
    !negative?
  end
  
  def negative?
    self.strength == 0
  end
  
  def inspect
    "<Tagging user=#{user.login}, item=#{feed_item.id}, tag=#{tag.name}, classifier=#{classifier_tagging?}>"
  end
  
  private
  def update_tag_timestamp
    self.tag.updated_on = Time.now.utc
    self.tag.save!
  end
  
  def remove_preexisting_tagging
    # Has this user tagged this item with this tag before?
    # This ensures that taggings are unique by user, taggable, tag and classifier_tagging
    user.taggings.find_by_feed_item(feed_item, :all, 
                                     :conditions => {
                                       :tag_id => tag.id,
                                       :classifier_tagging => classifier_tagging?
                                      }).
                                     each(&:destroy)
  end
end
