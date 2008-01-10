require File.dirname(__FILE__) + '/../spec_helper'

describe AdminController do
  fixtures :users, :roles, :roles_users

  def test_admin_can_access
    login_as(:admin)
    get :index
    assert_response :success
  end
  
  def test_admin_required
    cannot_access(:quentin, :get, :index)
  end
end
