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


# Represents messages that can be displayed to a User. Some messages are
# displayed to all users, while other are only displaed to a single user.
# When a User reads a message, it is marked as such via the ActsAsReadable 
# plugin. See its README file for details on readings.
class Message < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  
  validates_presence_of :body
    
  # Find messages to be displayed to all users
  named_scope :global, :conditions => { :user_id => nil }
  
  named_scope :for, lambda { |user|
    if user
      { :conditions => ["messages.user_id IS NULL OR messages.user_id = ?", user.id] }
    else
      { :conditions => "messages.user_id IS NULL" }
    end
  }
  
  named_scope :latest, lambda { |limit|
    { :limit => limit }
  }
  
  # Finds pinned messages or ones since the given date. Orders by most recent pinned and then message creation date.
  named_scope :pinned_or_since, lambda { |date| 
    { :conditions => ["messages.pinned = ? OR messages.created_at >= ?", true, date], :order => "messages.pinned DESC, messages.created_at DESC" }
  }
  
  def self.read_by!(user)
    readings_attributes = unread(user).for(user).map do |message|
      { :readable_type => "Message", :readable_id => message.id, :user_id => user.id }
    end

    Reading.create!(readings_attributes)
  end
  
  # Defines how old messages can be before they are no longer displayed
  # on the info page.
  def self.info_cutoff
    60.days.ago
  end
end
