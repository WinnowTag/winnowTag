# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require 'bulk_taggings_controller'

# Re-raise errors caught by the controller.
class BulkTaggingsController; def rescue_action(e) raise e end; end

class BulkTaggingsControllerTest < Test::Unit::TestCase
  fixtures :users, :feed_items, :feeds
  
  def setup
    @controller = BulkTaggingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    referer('/')
  end
 
  requires_post(:create, :user => :quentin, :redirect_to => '/', :params => {:filter => 1, :tag => 'unwanted', :exclusive => 'true'})
  requires_post(:destroy, :user => :quentin, :redirect_to => '/', :params => {:filter => 1, :tag => 'unwanted'})
   
  def test_destroy_bulk_tagging
    login_as(:quentin)
    
    BulkTagging.create(:filter => Feed.find(1), :tag => 'unwanted', :tagger => users(:quentin))
    
    post :destroy, :tag => 'unwanted', :filter => 1
    
    Feed.find(1).feed_items.each do |fi|
      assert_equal [], fi.taggings.find_by_tagger(users(:quentin))
    end
  end
    
  def test_create_bulk_tagging
    accept('text/html')
    login_as(:quentin)
    post :create, :filter => 1, :tag => 'unwanted', :exclusive => 'true'
    assert_response :redirect
    assert_not_nil assigns(:bulk_tagging)
    Feed.find(1).feed_items.each do |item|
      tagging = item.taggings.find_by_tagger(users(:quentin)).first
      assert_equal Tag.find_by_name('unwanted'), tagging.tag
      assert_equal 1.0, tagging.strength
      assert_equal users(:quentin), tagging.tagger
      assert_equal assigns(:bulk_tagging), tagging.metadata
    end
  end
end
