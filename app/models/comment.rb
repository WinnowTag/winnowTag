# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Comment < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :tag_id, :user_id, :body
  
  def self.find_for_user(user, id)
    if user.has_role?('admin')
      find(id)
    else
      find(id, :joins => "LEFT JOIN tags ON tags.id = comments.tag_id", :conditions => ["comments.user_id = ? OR tags.user_id = ?", user.id, user.id])
    end
  end
end
