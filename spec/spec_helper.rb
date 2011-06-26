# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'

require "selenium/rspec/spec_helper"
require 'authenticated_test_helper'
require 'active_resource/http_mock'
Dir[File.expand_path(File.join(File.dirname(__FILE__), "support", "*.rb"))].each { |file| require file }

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
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner

  # TODO: Pull this call into mhs_testing
  config.include ValidationMatchers, AssociationMatchers, :type => :model
  config.include CustomSeleniumHelpers, :type => :selenium
  config.include WinnowMatchers, :type => :code

  # Stub out User.encrypt for faster testing
  config.before(:each, :type => [:controllers, :helpers, :models, :views]) do
    User.stub!(:encrypt).and_return('password')
  end

  def login_as(user_or_user_id)
    session[:user] = case user_or_user_id
      when User;     user_or_user_id.id
      when Numeric;  user_or_user_id
      when NilClass; nil
      else           raise "Cannot login as #{user_or_user_id.inspect}"
    end
  end
  
  def current_user
    @controller.send(:current_user)
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
  
  def ie?
    Selenium::Configuration.browser =~ /iexplore/
  end
  
  def it_unless_ie(name, &block) 
    unless ie?
      it(name, &block)
    else
      xit("[IE Disabled] #{name}")
    end
  end
  
  include AuthenticatedTestHelper
end
