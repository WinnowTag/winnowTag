require File.dirname(__FILE__) + '/../spec_helper'

describe "moderation panel" do
  fixtures :users, :feed_items, :feeds, :feed_item_contents
  
  before(:each) do
    Tagging.delete_all
    Tag.delete_all
    ReadItem.delete_all
    
    @existing_tag = Tag.create! :user_id => 1, :name => "existing tag"
    
    login
    open feed_items_path
    wait_for_ajax
  end
  
  it "can be shown by clicking the add tag link" do
    assert_not_visible "new_tag_form_feed_item_4"
    click "add_tag_feed_item_4"
    wait_for_ajax 
    assert_visible "new_tag_form_feed_item_4"
  end
  
  xit "should focus the new tag field"
  
  # TODO: Enter is not being recognized by the auto complete code
  xit "can add a positive tagging from a new tag through the 'create a new tag' input" do
    click "add_tag_feed_item_4"
    wait_for_ajax
    
    dont_see_element "li[id='tag_control_for_new tag_on_feed_item_4']"

    sleep(2)
    type "new_tag_field_feed_item_4", "new tag"
    hit_enter "new_tag_field_feed_item_4"
    wait_for_effects
    
    see_element "li.positive[id='tag_control_for_new tag_on_feed_item_4']"
    get_text("tag_control_for_new tag_on_feed_item_4").should =~ /new tag/

    tag = Tag.find_by_name("new tag")
    # Adds tag to the sidebar
    see_element "li#tag_#{tag.id}"
  end
  
  # TODO: Enter is not being recognized by the auto complete code
  xit "can add a positive tagging from an existing tag through the 'create new tag' input" do 
    click "add_tag_feed_item_4" 
    wait_for_ajax 
     
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
     
    type "new_tag_field_feed_item_4", "existing tag"
    hit_enter "new_tag_field_feed_item_4"
    wait_for_effects
  
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    get_text("tag_control_for_existing tag_on_feed_item_4").should =~ /existing tag/
  end

  xit "can add a positive tagging from an existing tag through the 'create new tag' input when the tagging already exists"
  xit "does not select the first choice in the auto complete list"
  xit "uses the selected entry when clicking 'Add Tag'"
  xit "creates a new tag when hitting enter and not entry is selected"
  
  it "can change a positive tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a classifier tagging to a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a classifier tagging to a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a positive tagging to a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a negative tagging to a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    
    see_element "li.classifier[id='tag_control_for_existing tag_on_feed_item_4']"
    dont_see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
  end
  
  it "can change a positive tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.positive[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"

    get_confirmation # Ignore the confirmation to delete the tag
  end
  
  it "can change a negative tagging to a nothing tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    see_element "li.negative[id='tag_control_for_existing tag_on_feed_item_4']"
    
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    wait_for_ajax
    wait_for_effects
    
    dont_see_element "li[id='tag_control_for_existing tag_on_feed_item_4']"
    
    get_confirmation # Ignore the confirmation to delete the tag
  end
  
  it "changing tagging state does not open/close item" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    assert_not_visible "open_feed_item_4"
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    assert_not_visible "open_feed_item_4"
    click "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    assert_not_visible "open_feed_item_4"
  end
  
  it "shows the proper tooltip for a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_equal "Negative training example for Winnow", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4']@title")
  end
  
  it "shows the proper tooltip for a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_equal "Positive training example for Winnow", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4']@title")
  end
  
  it "shows the proper tooltip for a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_equal "Winnow figured this item fit your examples", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4']@title")
  end
  
  it "shows the proper tooltip for controls in a negative tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 0, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    assert_equal "Click if this is a very good example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add@title")

    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    assert_equal "Click to remove this negative example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove@title")
  end
  
  it "shows the proper tooltip for controls in a positive tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => false

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    assert_equal "Click to remove this positive example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add@title")

    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    assert_equal "Click if this is a bad example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove@title")
  end
  
  it "shows the proper tooltip for controls in a classifier tagging" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add"
    assert_equal "Click if this is a very good example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .add@title")

    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove"
    assert_equal "Click if this is a bad example of existing tag", get_attribute("css=li[id='tag_control_for_existing tag_on_feed_item_4'] .remove@title")
  end
  
  it "shows tagging controls when hovering the tag" do
    Tagging.create! :feed_item_id => 4, :tag_id => @existing_tag.id, :strength => 1, :user_id => 1, :classifier_tagging => true

    open feed_items_path
    wait_for_ajax
    
    assert_not_visible "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .controls"
    mouse_over "css=li[id='tag_control_for_existing tag_on_feed_item_4']"
    assert_visible "css=li[id='tag_control_for_existing tag_on_feed_item_4'] .controls"
  end
end
