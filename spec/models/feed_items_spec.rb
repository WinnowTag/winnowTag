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
    
    view = user_1.views.create!
    view.add_tag :include, tag_1
    view.add_tag :exclude, tag_2
    
    FeedItem.find_with_filters(:view => view, :order => 'feed_items.id').should == [feed_item_1]
  end
end
