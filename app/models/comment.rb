class Comment < ActiveRecord::Base
  validates_presence_of :tag_id, :user_id, :body
end
