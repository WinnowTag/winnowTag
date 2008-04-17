# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class FeedItemTextIndex < ActiveRecord::Base
  set_primary_key "feed_item_id"
  belongs_to :feed_item
  before_create :normalize_content
  
  private
  def normalize_content
    if self.content.nil? && self.feed_item
      self.content = self.feed_item.title + ' ' + self.feed_item.content.content
    end
    
    if self.content
      self.content.gsub!(/<\/?\w+>/, ' ')
      self.content.strip!
    end
  end
end
