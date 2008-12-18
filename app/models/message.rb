# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Message < ActiveRecord::Base
  acts_as_readable
  
  belongs_to :user
  
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
    find(:all, :joins => sanitize_sql(["LEFT JOIN readings ON readings.readable_type = 'Message' AND readings.readable_id = messages.id AND readings.user_id = ?", user_id]), 
               :conditions => ["readings.id IS NULL AND (messages.user_id = ? OR messages.user_id IS NULL)", user_id])
  end

  def self.read_by!(user)
    readings_attributes = find_unread_for_user_and_global(user.id).map do |message|
      { :readable_type => "Message", :readable_id => message.id, :user_id => user.id }
    end

    Reading.create!(readings_attributes)
  end
end
