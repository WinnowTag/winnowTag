# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# A TagGroup is a group of Tag Publications that belong to user
# or in the case of global tag groups they belong to everyone.
#
# TagGroups are one of the ways to share tags between users in Winnow.
# A user can publish one of their own tags to a global Tag Group to make
# it visible for other users.
#
class TagGroup < ActiveRecord::Base
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  has_many :tag_publications
  attr_protected :owner_id
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.find_globals(options = {})    
    self.find(:all, options.dup.update(:conditions => {:global => true}))
  end
  
  def self.new_global(params = {})
    returning(self.new(params)) do |tag_group|
      tag_group.global = true
      tag_group.publically_readable = true
      tag_group.publically_writeable = true
    end
  end
  
  def self.create_global(params = {})
    returning(self.new_global(params)) do |tag_group|
      tag_group.save
    end
  end
  
  # Add first and last methods so they can easily be used in a select box
  def first; self.name; end
  def last;  self.id;   end
end
