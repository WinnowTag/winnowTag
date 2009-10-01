# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a comment on a Tag by a User.
#
# The ActsAsReadable plugin handles marking comments read/unread per user.
# See its README file for details.
class Comment < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :tag_id, :user_id, :body
  
  # Finds the requested comment, while providing a level of access control
  # based on the user.
  # 
  # Admin users will be able to access any comment.
  # 
  # Non-Admin users will only be able to access comments they created ors 
  # comments left on their tags.
  def self.find_for_user(user, id)
    if user.has_role?('admin')
      find(id)
    else
      find(id, 
        :joins => "LEFT JOIN tags ON tags.id = comments.tag_id", 
        :conditions => ["comments.user_id = ? OR tags.user_id = ?", user.id, user.id]
      )
    end
  end
end
