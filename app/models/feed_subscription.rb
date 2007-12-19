class FeedSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :feed
  
  validates_presence_of :user_id, :feed_id
end
