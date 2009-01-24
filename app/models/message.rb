# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Message < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  
  validates_presence_of :body
    
  named_scope :global, :conditions => { :user_id => nil }
  named_scope :for, lambda { |user|
    { :conditions => ["messages.user_id IS NULL OR messages.user_id = ?", user.id] }
  }
  
  named_scope :latest, lambda { |limit|
    { :order => "created_at DESC", :limit => limit }
  }
  
  def self.read_by!(user)
    readings_attributes = unread(user).for(user).map do |message|
      { :readable_type => "Message", :readable_id => message.id, :user_id => user.id }
    end

    Reading.create!(readings_attributes)
  end
end
