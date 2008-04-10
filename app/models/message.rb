class Message < ActiveRecord::Base
  validates_presence_of :body
  
  def to_s
    body
  end
  
  def self.find_global
    find(:all, :conditions => { :user_id =>  nil })
  end
  
  def self.find_for_user_and_global(user_id)
    find(:all, :conditions => ["user_id = ? OR user_id IS NULL", user_id])
  end
end