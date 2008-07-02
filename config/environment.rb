# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# TODO: Move this out of environment.rb
# Need to require this first so I can setup at_exit handlers to run AFTER test/unit at_exit handler which runs tests
require File.join(RAILS_ROOT, %w[vendor plugins mhs_testing lib selenium at_exit])

# TODO: Submit rails patch to fix this problem
# Need to require this first so 3.0.4 does not get required by action pack
gem 'RedCloth', '3.0.3'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "fastercsv"
  # config.gem "RedCloth", :version => "3.0.3"
  config.gem "ratom", :version => "0.3.6", :lib => "atom"

  # Must be compiled
  config.gem "mysql"
  config.gem "hpricot"
  config.gem "bcrypt-ruby", :lib => "bcrypt"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/mailers )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_winnow_session',
    :secret      => 'd768f297dcbe7a3afaebeb4d2f7022b30822109291263eec7af980b787d5a1a8ca56833de2bc75f8a26777d5d974d20aac2c6316e2f4786fdd7f17771f9ee1be'
  }
  
  config.action_controller.filter_parameter_logging = :password
  
  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :text_indexing_observer
  
  config.after_initialize do 
    ActionView::Helpers::AssetTagHelper.register_javascript_expansion :winnow => ["slider", "cookies", "applesearch", "bias_slider", "messages", "labeled_input", "scroll", "classification", "itembrowser", "item", "sidebar", "tagging"]
    ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :winnow => ["winnow", "tables", "slider", "scaffold"]
  end
end
