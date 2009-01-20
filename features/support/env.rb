# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
Cucumber::Rails.use_transactional_fixtures

# Comment out the next line if you're not using RSpec's matchers (should / should_not) in your steps.
require 'cucumber/rails/rspec'

# TODO: Remove the need for mocks/stubs in features
require 'spec/mocks'

require Pathname.new(Rails.root).join(*%w[spec support generate])
require Pathname.new(Rails.root).join(*%w[spec support valid_attributes])

class Cucumber::Rails::World
  include ValidAttributes
  
  attr_accessor :current_user
end

class Webrat::SearchField < Webrat::TextField
end
