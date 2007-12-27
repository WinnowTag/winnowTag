require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItem do

  it "Properly filters feed items with included private tag and excluded public tag" do
    user_1 = User.create! valid_user_attributes
    user_2 = User.create! valid_user_attributes
        
    tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    tag_2 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
    tag_3 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    
    tag_subscription = TagSubscription.create! :tag_id => tag_1.id, :user_id => user_1.id
    
    feed_item_1 = FeedItem.create! valid_feed_item_attributes
    feed_item_2 = FeedItem.create! valid_feed_item_attributes
    feed_item_3 = FeedItem.create! valid_feed_item_attributes
    
    tagging_1 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_1.id, :tag_id => tag_1.id
    tagging_2 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_2.id, :tag_id => tag_2.id
    tagging_3 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_3.id, :tag_id => tag_3.id
    
    user_1.tag_exclusions.create! :tag_id => tag_2.id
    
    FeedItem.find_with_filters(:user => user_1, :tag_ids => tag_1.id.to_s, :order => 'feed_items.id').should == [feed_item_1]
  end

  it "Properly filters feed items with included private tag, excluded private tag, and excluded public tag" do
    user_1 = User.create! valid_user_attributes
    user_2 = User.create! valid_user_attributes
        
    tag_1 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    tag_2 = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
    tag_3 = Tag.create! valid_tag_attributes(:user_id => user_1.id)
    
    tag_subscription = TagSubscription.create! :tag_id => tag_1.id, :user_id => user_1.id
    
    feed_item_1 = FeedItem.create! valid_feed_item_attributes
    feed_item_2 = FeedItem.create! valid_feed_item_attributes
    feed_item_3 = FeedItem.create! valid_feed_item_attributes
    feed_item_4 = FeedItem.create! valid_feed_item_attributes
    
    tagging_1 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_1.id, :tag_id => tag_1.id
    tagging_2 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_2.id, :tag_id => tag_2.id
    tagging_3 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_3.id, :tag_id => tag_3.id
    tagging_4 = Tagging.create! :user_id => user_1.id, :feed_item_id => feed_item_4.id, :tag_id => tag_1.id
    tagging_5 = Tagging.create! :user_id => user_2.id, :feed_item_id => feed_item_4.id, :tag_id => tag_2.id
    
    user_1.tag_exclusions.create! :tag_id => tag_2.id
    user_1.tag_exclusions.create! :tag_id => tag_3.id
    
    FeedItem.find_with_filters(:user => user_1, :tag_ids => tag_1.id.to_s, :order => 'feed_items.id').should == [feed_item_1]
  end
  
  it "properly filters on globally excluded feeds" do
    user_1 = User.create! valid_user_attributes
    
    feed_1 = Feed.create! :url => "http://feedone.com"
    
    FeedItem.delete_all # :(
    feed_item_1 = FeedItem.create! valid_feed_item_attributes(:feed_id => feed_1.id)
    feed_item_2 = FeedItem.create! valid_feed_item_attributes(:feed_id => feed_1.id)
    feed_item_3 = FeedItem.create! valid_feed_item_attributes(:feed_id => 2)
    feed_item_4 = FeedItem.create! valid_feed_item_attributes(:feed_id => 3)
    
    user_1.excluded_feeds << feed_1
    
    FeedItem.find_with_filters(:user => user_1, :order => 'feed_items.id').should == [feed_item_3, feed_item_4]
  end
end
