# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Stores the contents for a feed item. This is the title, author,
# description and encoded content extracted from the original XML.
#
# == Schema Information
# Schema version: 57
#
# Table name: feed_item_contents
#
#  id              :integer(11)   not null, primary key
#  feed_item_id    :integer(11)   
#  title           :text          
#  link            :string(255)   
#  author          :string(255)   
#  description     :text          
#  created_on      :datetime      
#  encoded_content :text          
#

class FeedItemContent < ActiveRecord::Base
  belongs_to :feed_item
  set_primary_key "feed_item_id"
end
