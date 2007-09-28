# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require 'global_tag_groups_controller'

# Re-raise errors caught by the controller.
class GlobalTagGroupsController; def rescue_action(e) raise e end; end

class GlobalTagGroupsControllerTest < Test::Unit::TestCase
  fixtures :tag_groups, :users, :tag_publications

  def setup
    @controller = GlobalTagGroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  # Replace this with your real tests.
  def test_index
    get :index, :view_id => users(:admin).views.create
    assert_response :success
    assert_equal(TagGroup.find_globals, assigns(:global_tag_groups))
  end
  
  def test_shows_tag_publications_table
    get :index, :view_id => users(:admin).views.create
    assert_select("table tr td", TagGroup.find(1).tag_publications.first.tag.name, @response.body)
  end

  def test_requires_admin
    cannot_access(:quentin, :get, :index) 
    cannot_access(:quentin, :post, :destroy) 
  end
  
  def test_create_form
    get :new, :view_id => users(:admin).views.create
    assert_select("form[action = '/global_tag_groups']", true)
  end
  
  def test_global_tag_group_creation
    assert_difference(TagGroup, :count) do
      post :create, :global_tag_group => {:name => 'test', :description => 'description'}
    end
  end
  
  def test_destroy_tag_group
    assert_difference(TagGroup, :count, -1) do
      referer("/")
      post :destroy, :id => 1
    end
  end
  
  def test_destroy_requires_admin
    assert_no_difference(TagGroup, :count) do
      login_as(:quentin)
      post :destroy, :id => 1
    end
  end
end
