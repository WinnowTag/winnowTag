class Comment < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :tag_id, :user_id, :body
end
