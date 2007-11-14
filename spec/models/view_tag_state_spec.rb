require File.dirname(__FILE__) + '/../spec_helper'

describe ViewTagState do
  it "deleting tag state for all users" do
    owner = User.create! valid_user_attributes
    subscriber = User.create! valid_user_attributes
    
    tag = owner.tags.create! :name => "tag", :public => true
    
    owners_view = owner.views.create!
    owners_view.add_tag :include, tag
    subscribers_view = subscriber.views.create!
    subscribers_view.add_tag :include, tag
    
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    ViewTagState.delete_all_for(tag)
    
    assert_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    assert_not_nil View.find(owners_view.id)
    assert_not_nil View.find(subscribers_view.id)
  end
  
  it "deleting tag state expect for a certain user" do
    owner = User.create! valid_user_attributes
    subscriber = User.create! valid_user_attributes
    
    tag = owner.tags.create! :name => "tag", :public => true
    
    owners_view = owner.views.create!
    owners_view.add_tag :include, tag
    subscribers_view = subscriber.views.create!
    subscribers_view.add_tag :include, tag
    
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    ViewTagState.delete_all_for(tag, :except => owner)
    
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    assert_not_nil View.find(owners_view.id)
    assert_not_nil View.find(subscribers_view.id)
  end
  
  it "deleting tag state for only a certain user" do
    owner = User.create! valid_user_attributes
    subscriber = User.create! valid_user_attributes
    
    tag = owner.tags.create! :name => "tag", :public => true
    
    owners_view = owner.views.create!
    owners_view.add_tag :include, tag
    subscribers_view = subscriber.views.create!
    subscribers_view.add_tag :include, tag
    
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    ViewTagState.delete_all_for(tag, :only => subscriber)
    
    assert_not_nil ViewTagState.find_by_view_id_and_tag_id(owners_view, tag)
    assert_nil ViewTagState.find_by_view_id_and_tag_id(subscribers_view, tag)
    
    assert_not_nil View.find(owners_view.id)
    assert_not_nil View.find(subscribers_view.id)
  end
end