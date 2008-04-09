class Message < ActiveRecord::Base
  validates_presence_of :body
  
  def to_s
    body
  end
end
