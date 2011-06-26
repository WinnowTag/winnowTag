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
