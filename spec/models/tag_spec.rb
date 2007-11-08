require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  it "Properly calculates tagging counts when tags are included in many views" do
    user_1 = User.create! valid_user_attributes
    user_2 = User.create! valid_user_attributes
    
    tag = Tag.create! valid_tag_attributes(:user_id => user_2.id, :public => true)
    tag_subscription = TagSubscription.create! :user_id => user_1.id, :tag_id => tag.id
    
    feed_item_1 = FeedItem.create! valid_feed_item_attributes
    feed_item_2 = FeedItem.create! valid_feed_item_attributes
    
    tagging_1 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_1.id
    tagging_2 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_2.id, :strength => 0.95, :classifier_tagging => true
    tagging_3 = Tagging.create! :tag_id => tag.id, :user_id => user_2.id, :feed_item_id => feed_item_2.id, :strength => 0
    
    view_1 = user_1.views.create!
    view_1.add_tag :include, tag
    view_2 = user_1.views.create!
    view_2.add_tag :include, tag
    
    tags = Tag.find_all_with_count(:view => view_1, :user => user_1, :subscriber => user_1)
    tags.should have(1).record
    
    tags.first.positive_count.should == "1"
    tags.first.negative_count.should == "1"
    tags.first.classifier_count.should == "1"
  end
end
