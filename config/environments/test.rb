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
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

# Must be compiled/installed on the target system
config.gem "term-ansicolor", :lib => "term/ansicolor",  :version => "1.0.3"
config.gem "polyglot",       :lib => false,             :version => "0.2.5"
config.gem "treetop",        :lib => "treetop/runtime", :version => "1.2.5"

# Not bundled until we can deploy without test dependencies being built
# See http://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1793-make-rake-gemsbuild-respect-railsenv
config.gem "nokogiri",                                  :version => "1.2.3"

# Bundled in vendor/gems
config.gem "webrat"
config.gem "diff-lcs",        :lib => "diff/lcs"
config.gem "rspec",           :lib => false
config.gem "rspec-rails",     :lib => false
config.gem "cucumber",        :lib => false
config.gem "selenium-client", :lib => "selenium/client"