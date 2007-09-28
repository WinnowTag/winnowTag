# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Tag publications are created when a user publishes a tag to 
# TagGroup for other users to use. When the TagPublication is 
# created, the current state of the publishers tag is copied
# to the TagPublication and the publication is associated
# with the target TagGroup.
#
class TagPublication < ActiveRecord::Base
  before_create :create_classifier
  after_create :set_bias
  after_create :remove_previous_version
  after_create :duplicate_taggings
  acts_as_tagger
  belongs_to :publisher, :class_name => "User", :foreign_key => "publisher_id"
  belongs_to :tag
  belongs_to :tag_group
  has_one :classifier, :class_name => "BayesClassifier", :as => :tagger, :dependent => :destroy
  validates_presence_of :tag, :publisher, :tag_group, :on => :create
  
  # Finds all TagPublications published by publishers other that publisher
  #
  def self.find_by_other_publisher(publisher)
    find(:all, :conditions => ['publisher_id <> ?', publisher])
  end
  
  # Gets the number of manual positive taggings.
  def positive_count
    self.taggings.count(:conditions => "strength = 1")
  end
  
  # Gets the number of negative taggings.
  def negative_count
    self.taggings.count(:conditions => "strength = 0")
  end
  
  # Gets the number of classifier assigned positive taggings.
  def classifier_count
    self.classifier.taggings.count(:conditions => "strength > 0.88")
  end
  
  # Gets a representation of the tag in a form suitable for use as a tag_filter
  def filter_value
    "pub_tag:#{self.id}"
  end
  
  # Gets a human friendly name of the tag publication.
  def name
    "#{publisher.login}:#{tag.name}"
  end
  
  alias_method :classification_label, :name
  
  protected
  def remove_previous_version
    if prev = self.publisher.tag_publications.find(:first, 
                  :conditions => ['tag_id = ? and tag_group_id = ? and id <> ?', 
                                  self.tag_id, self.tag_group_id, self.id])
      prev.destroy
    end
    
    true
  end
  
  def duplicate_taggings
    self.publisher.copy_tag(self.tag, self.tag, self)
  end
  
  def set_bias
    self.classifier.bias = {self.tag.name => self.publisher.classifier.bias[self.tag.name]}
    self.classifier.save
  end
end
