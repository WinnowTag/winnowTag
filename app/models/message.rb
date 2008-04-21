# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class Message < ActiveRecord::Base
  validates_presence_of :body
  
  def to_s
    body
  end
  
  def self.find_global
    find(:all, :conditions => { :user_id =>  nil })
  end
  
  def self.find_for_user_and_global(user_id, options = {})
    find(:all, options.merge(:conditions => ["user_id = ? OR user_id IS NULL", user_id]))
  end
end
