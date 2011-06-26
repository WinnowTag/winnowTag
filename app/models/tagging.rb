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


# Tagging is the core class within Winnow's tagging infra-structure.
# A Tagging can be thought of as the application of a Tag to a FeedItem
# by a User.
#
# == Immutability and Destruction
#
# A Tagging is immutable, i.e., once created it can never be changed.
#
# When a Tagging is destroyed, it is captured as a DeletedTagging.
#
# == Tagging Strength
#
# A Tagging has a +strength+ attribute that defines its positivity. The meaning of this attribute
# is dependent on the +classifier_tagging+ attribute. For example, when +classifier_tagging+ is +false+,
# a strength of 1 is a positive tagging and a strength of 0 is a negative tagging. When +classifier_tagging+
# is +true+, the strength is the probability that the classifier would assign the tag, and a probability
# over the classifier's +positive_cutoff+ should be considered positive.
class Tagging < ActiveRecord::Base
  acts_as_immutable
  
  belongs_to :tag
  belongs_to :feed_item
  belongs_to :user
  
  validates_presence_of :tag, :user, :feed_item
  validates_numericality_of :strength
  validates_inclusion_of :strength, :in => 0..1
  validates_associated :tag

  # When creating a tagging, tags are often auto-created as well.
  # Because of this, we will copy errors from the tag to the tagging
  # to display them to the user.
  after_validation do |tagging|
    tagging.errors.delete(:tag)

    tagging.tag.errors.each do |attribute, message|
      tagging.errors.add(:tag, message)
    end if tagging.tag
  end
  
  # See the definition of these methods below to learn about each of these callbacks
  before_create  :remove_preexisting_tagging
  after_create   :update_tag_timestamp
  before_destroy :update_tag_timestamp
  after_destroy  :create_deleted_tagging
  
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
  # Has this user tagged this item with this tag before?
  # This ensures that taggings are unique by user, taggable, tag and classifier_tagging
  def remove_preexisting_tagging
    user.taggings.find(:all, 
      :conditions => { :tag_id => tag.id, :feed_item_id => feed_item.id, :classifier_tagging => classifier_tagging? }
    ).each(&:destroy)
  end
  
  def update_tag_timestamp
    tag.update_attribute(:updated_on, Time.now.utc)
  end
  
  def create_deleted_tagging
    DeletedTagging.create(attributes.merge(:deleted_at => Time.now.utc))
  end
end
