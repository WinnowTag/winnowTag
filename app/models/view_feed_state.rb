class ViewFeedState < ActiveRecord::Base
  belongs_to :view
  belongs_to :feed
end
