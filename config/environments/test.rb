# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Must be compiled/installed on the target system
config.gem "term-ansicolor", :version => "1.0.3", :lib => "term/ansicolor"
config.gem "polyglot", :version => "0.2.3", :lib => false
config.gem "treetop", :version => "1.2.4", :lib => "treetop/runtime"

# Bundled in vendor/gems
config.gem "nokogiri"
config.gem "webrat"
config.gem "diff-lcs", :lib => "diff/lcs"
config.gem "rspec", :lib => false
config.gem "rspec-rails", :lib => false
config.gem "cucumber", :lib => false
config.gem "selenium-client", :lib => "selenium/client"
