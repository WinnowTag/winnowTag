# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

require 'authenticated_test_helper'
require 'active_resource/http_mock'
require File.join(RAILS_ROOT, *%w[vendor plugins mhs_testing lib selenium example_group])
require File.expand_path(File.join(File.dirname(__FILE__), "generate"))

module CustomSeleniumHelpers
  def login(login = "quentin", password = "test")
    open login_path
    type "login", login
    type "password", password
    click_and_wait "commit"
  end

  def click_and_wait(locator, timeout = 30000)
    click locator
    wait_for_page_to_load(timeout)
  end

  def refresh_and_wait(timeout = 30000)
    refresh
    wait_for_page_to_load(timeout)
  end

  def see_element(*args)
    assert is_element_present("css=#{args.join}")
  end

  def dont_see_element(*args)
    assert !is_element_present("css=#{args.join}")
  end

  def assert_visible(locator)
    assert is_visible(locator)
  end

  def assert_not_visible(locator)
    assert !is_visible(locator)
  end

  def assert_element_disabled(selector)
    see_element("#{selector}[disabled]")
  end

  def assert_element_enabled(selector)
    dont_see_element("#{selector}[disabled]")
  end
  
  def hit_enter(locator)
    key_press locator, '\13'
  end
  
  def wait_for_ajax(timeout = 30000)
    wait_for_condition "window.Ajax.activeRequestCount == 0", timeout
  end
  
  def wait_for_effects(timeout = 30000)
    wait_for_condition "window.Effect.Queue.size() == 0", timeout
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner

  # TODO: Pull this call into mhs_testing
  config.include ValidationMatchers, AssociationMatchers, :type => :model
  config.include CustomSeleniumHelpers, :type => :selenium

  # Stub out User.encrypt for faster testing
  config.before(:each) do
    User.stub!(:encrypt).and_return('password')
  end

  def valid_feed_item_attributes(attributes = {})
    unique_id = rand(10000)
    { :link => "http://#{unique_id}.example.com",
      :id => unique_id # Add this since it is no longer an autoincrement column
    }.merge(attributes)
  end
  
  def valid_feed_item!(attributes = {})
    attributes = valid_feed_item_attributes(attributes)
    fi = FeedItem.new(attributes)
    fi.id = attributes[:id]
    fi.save!
    fi
  end
  
  def valid_feed_attributes(attributes = {})
    unique_id = rand(100000)
    { :via => "http://#{unique_id}.example.com/index.xml",
      :alternate => "http://#{unique_id}.example.com",
      :title => "#{unique_id} Example",
      :feed_items_count => 0,
      :updated_on => Time.now,
      :duplicate_id => nil
    }.merge(attributes)
  end
  
  def valid_user_attributes(attributes = {})
    unique_id = rand(100000)
    { :login => "user_#{unique_id}",
      :email => "user_#{unique_id}@example.com",
      :password => "password",
      :password_confirmation => "password",
      :firstname => "John_#{unique_id}",
      :lastname => "Doe_#{unique_id}",
      :time_zone => "UTC"
    }.merge(attributes)
  end
  
  def valid_tag_attributes(attributes = {})
    unique_id = rand(1000)
    {
      :name => "Tag #{unique_id}",
      :user_id => unique_id
    }.merge(attributes)
  end
  
  def valid_invite_attributes(attributes = {})
    unique_id = rand(1000)
    {
      :email => "user_#{unique_id}@example.com"
    }.merge(attributes)
  end
  
  def login_as(user_id_or_fixture_name)
    session[:user] = case user_id_or_fixture_name
      when User;    user_id_or_fixture_name.id
      when Numeric; user_id_or_fixture_name
      when Symbol;  users(user_id_or_fixture_name).id
    end
  end
  
  def current_user
    @controller.send(:current_user)
  end
  
  def print_response_body
    puts ERB::Util.html_escape(response.body)
  end
  
  def mock_new_model(model_class, options_and_stubs = {})
    mock_model(model_class, options_and_stubs.reverse_merge(:id => nil, :to_param => nil, :new_record? => true))
  end
  
  def mock_user_for_controller
    @user = mock_model(User, valid_user_attributes)
    @tags = mock("tags")
    
    User.stub!(:find_by_id).and_return(@user)
    @user.stub!(:tags).and_return(@tags)
    @user.should_receive(:update_attribute).any_number_of_times.with(:last_accessed_at, anything).and_return(true)
  end
  
  def mock_model_with_dom_id(cls, attributes)
    m = mock_model(cls, attributes)    
    m.stub!(:dom_id).with(no_args()).and_return("#{cls.name.underscore}_#{m.id}")
    m.should_receive(:dom_id).with(an_instance_of(String)).any_number_of_times.and_return {|p| "#{p}_#{cls.name.underscore}_#{m.id}"}
    m
  end
  
  def referer(referer)
    @request.env['HTTP_REFERER'] = referer
  end

  # This helper was inspired by the authorize plugin Integration Tests
  # See: http://svn.writertopia.com/svn/testapps/object_roles_test/test/integration/stories_test.rb
  def cannot_access(user, method, action, args = {})
    login_as(user)
    self.send(method, action, args)
    assert_response :redirect
    assert_redirected_to "/account/login"
  end
  
  include AuthenticatedTestHelper
  def assert_requires_login(login = nil)
    yield HttpLoginProxy.new(self, login)
  end
end
