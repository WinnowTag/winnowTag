require File.dirname(__FILE__) + '/../test_helper'

class RoleTest < Test::Unit::TestCase
  fixtures :roles, :users, :roles_users

  # Replace this with your real tests.
  def test_admin_user_has_admin_role
    assert users(:admin).has_role?('admin')
  end
end
