require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :users, :roles, :roles_users
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_admin_can_access
    login_as(:admin)
    get :index
    assert_response :success
  end
  
  def test_admin_required
    cannot_access(:quentin, :get, :index)
  end
end
