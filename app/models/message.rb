# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents messages that can be displayed to a User. Some messages are
# displayed to all users, while other are only displaed to a single user.
# When a User reads a message, it is marked as such via the ActsAsReadable 
# plugin. See its README file for details on readings.
class Message < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  
  validates_presence_of :body
    
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
