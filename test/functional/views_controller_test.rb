# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require File.dirname(__FILE__) + '/../test_helper'
require 'views_controller'

# Re-raise errors caught by the controller.
class ViewsController; def rescue_action(e) raise e end; end

class ViewsControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = ViewsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @view_id = "9"

    login_as(:admin)    
    current_user = users(:admin)
    User.stubs(:find_by_id).returns(current_user)
    
    mock_views = mock
    current_user.expects(:views).returns(mock_views)
    
    @mock_view = mock
    mock_views.expects(:find).with(@view_id).returns(@mock_view)
  end

  def test_adding_include_feed_to_current_view    
    feed_id = 1
    feed_state = :include

    @mock_view.expects(:add_feed).with(feed_state, feed_id.to_s)
    @mock_view.expects(:save!)
    post :add_feed, :id => @view_id, :feed_id => feed_id, :feed_state => feed_state
  end

  def test_removing_include_feed_from_current_view    
    feed_id = 1
    
    @mock_view.expects(:remove_feed).with(feed_id.to_s)
    @mock_view.expects(:save!)
    post :remove_feed, :id => @view_id, :feed_id => feed_id
  end
end
