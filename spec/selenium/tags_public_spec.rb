require File.dirname(__FILE__) + '/../spec_helper'

describe "TagsPublicTest" do
  fixtures :users
  
  before(:each) do
    Tag.delete_all
    user = User.create! valid_user_attributes
    @tag = Tag.create! :name => "foo", :public => true, :user_id => user.id
    
    login
    open public_tags_path
    
    wait_for_ajax
  end
  
  it "subscribes to a public tag" do    
    dont_see_element "#tag_#{@tag.id}.subscribed"
    assert !is_checked("subscribe_tag_#{@tag.id}")
    assert is_checked("neither_tag_#{@tag.id}")
    click "subscribe_tag_#{@tag.id}"
    
    wait_for_ajax 
  
    see_element "#tag_#{@tag.id}.subscribed"
    assert is_checked("subscribe_tag_#{@tag.id}")
    assert !is_checked("neither_tag_#{@tag.id}")
    
    refresh_and_wait
    wait_for_ajax
    
    see_element "#tag_#{@tag.id}.subscribed"
    assert is_checked("subscribe_tag_#{@tag.id}")
    assert !is_checked("neither_tag_#{@tag.id}")
  end
  
  it "globally excludes a public tag" do
    dont_see_element "#tag_#{@tag.id}.globally_excluded"
    assert !is_checked("globally_exclude_tag_#{@tag.id}")
    assert is_checked("neither_tag_#{@tag.id}")
    click "globally_exclude_tag_#{@tag.id}"
    
    wait_for_ajax 

    see_element "#tag_#{@tag.id}.globally_excluded"
    assert is_checked("globally_exclude_tag_#{@tag.id}")
    assert !is_checked("neither_tag_#{@tag.id}")
    
    refresh_and_wait
    wait_for_ajax
    
    see_element "#tag_#{@tag.id}.globally_excluded"
    assert is_checked("globally_exclude_tag_#{@tag.id}")
    assert !is_checked("neither_tag_#{@tag.id}")
  end
end
