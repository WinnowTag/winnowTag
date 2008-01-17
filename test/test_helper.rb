ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + '/selenium_helper')
require 'active_resource/http_mock'

begin
  require 'redgreen' unless ENV['TM_MODE']
rescue(MissingSourceFile) 
  true 
end

require 'mocha'

class Test::Unit::TestCase
  include AuthenticatedTestHelper
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  def assert_association(source, macro, name, options = {})
    options[:class_name] ||= case macro
      when :belongs_to, :has_one: name.to_s.camelize
      when :has_many, :has_and_belongs_to_many: name.to_s.singularize.camelize
    end
    
    if options[:polymorphic]
      options[:foreign_type] = "#{name}_type"
    end
    
    reflection = source.reflect_on_association( name )
    assert_not_nil reflection, "#{source}.#{macro} #{name.inspect} is not defined"
    assert_equal options[:class_name].constantize, reflection.klass, 'associated to wrong class'  unless options[:polymorphic]
    assert_equal macro, reflection.macro, 'wrong type of association'
    # assert_equal options, reflection.options, 'incorrect association options'
  end

  def assert_valid(o, msg = "The object should be valid")
    assert o.valid?, msg + ': ' + o.errors.full_messages.join(", ")
  end
  
  def assert_invalid(o, msg = "The object should be invalid")
    assert !o.valid?, msg
  end
  
  def self.requires_post(action, options = {})
    self.send(:define_method, "test_#{action}_requires_post".to_sym) do
      user = options[:user] || :quentin
      login_as(user)
      get action, options[:params], options[:session]
      assert_response :redirect
      assert_redirected_to options[:redirect_to] if options[:redirect_to]
      assert_equal "Action can not be called with HTTP get", flash[:error]
    end
  end
  
  def assert_action_requires_post(action, options)    
    get action, options[:params], options[:session]
    assert_response :redirect
    assert_redirected_to options[:redirect_to] if options[:redirect_to]
    assert_equal "Action can not be called with HTTP get", flash[:error]
    yield(:get) if block_given?
    
    post action, options[:params], options[:session]
    assert_response :redirect
    assert_redirected_to options[:redirect_to] if options[:redirect_to]
    yield(:post) if block_given?
  end
  
  # These helpers were inspired by the authorize plugin Integration Tests
  # See: http://svn.writertopia.com/svn/testapps/object_roles_test/test/integration/stories_test.rb
  def cannot_access(user, method, action, args = {})
    login_as(user)
    self.send(method, action, args)
    assert_response :redirect
    assert_redirected_to "/account/login"
  end
  
  def referer(referer)
    @request.env['HTTP_REFERER'] = referer
  end
  
  def assert_include(o, arr, msg = "#{o.to_s} not found in #{arr.inspect}")
    assert arr.include?(o), msg
  end
  
  def assert_not_include(o, arr, msg = "#{o.to_s} not found in #{arr.inspect}")
    assert !arr.include?(o), msg
  end
end

Test::Unit::SeleniumTestCase # auto-requires this class
class Test::Unit::SeleniumTestCase
  include SeleniumHelper

  self.use_transactional_fixtures = false
end