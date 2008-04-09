class Message < ActiveRecord::Base
  validates_presence_of :body
  
  def to_s
    body
  end
  
  def self.find_global
    find(:all, :conditions => { :user_id =>  nil })
  end
end
