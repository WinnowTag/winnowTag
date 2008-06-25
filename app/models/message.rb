# Copyright (c) 2008 The Kaphan Foundation
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
  
  def self.find_unread_for_user_and_global(user_id)
    find(:all, :joins => sanitize_sql(["LEFT JOIN message_readings ON message_readings.message_id = messages.id AND message_readings.user_id = ?", user_id]), 
               :conditions => ["message_readings.id IS NULL AND (messages.user_id = ? OR messages.user_id IS NULL)", user_id])
  end

  def self.mark_read_for(user_id, message_id = nil)
    messages_attributes = if message_id
      { :message_id => message_id, :user_id => user_id }
    else
      find_unread_for_user_and_global(user_id).map do |message|
        { :message_id => message.id, :user_id => user_id }
      end
    end
    MessageReading.create!(messages_attributes)
  end
end
