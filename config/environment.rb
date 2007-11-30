# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# DWS - In our configuration, when running behind Apache, RAILS_ROOT
#       is incorrectly set to /comm/pwo/www.peerworks.org. The following
#       lines pull in a definition for RAILS_ROOT from an environment
#       variable that may be set in the Apache configuration file. If
#       running under WEBrick RAILS_ROOT will have been already defined,
#       and no action is taken.
#
# As yet unknown whether needed in non-IMS configuration.
#
# if !defined? RAILS_ROOT
#   RAILS_ROOT = ENV['RAILS_ROOT']
# end
# load any host specific configuration

host_specific_config = File.join(File.dirname(__FILE__), 'local', 'environment.rb')
if File.exist?(host_specific_config)
  require host_specific_config
end

AUTHORIZATION_MIXIN = 'object roles'
STORE_LOCATION_METHOD = :store_location

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
ENV['INLINEDIR'] = File.join(RAILS_ROOT, '.ruby_inline')

# Need to require this first so i can setup at_exit handlers to run AFTER test/unit at_exit handler which runs tests
require File.join(RAILS_ROOT, %w[vendor plugins selenium_jelly lib selenium at_exit])

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :user_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

require 'rubygems' # this is need on stonecutter for some reason
require 'hpricot'
require 'digest/sha1'
require 'tzinfo'

# Use SQL Session Store
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:database_manager => SqlSessionStore)
SqlSessionStore.session_class = MysqlSession

ExceptionNotifier.exception_recipients = %w(wizzadmin@peerworks.org)
ExceptionNotifier.email_prefix = "[WINNOW] "
ExceptionNotifier.sender_address = %("Winnow Admin" <wizzadmin@peerworks.org>)

Bayes::TokenAtomizer.store = :db

require 'array_ext'
require 'hash_ext'
require 'module_ext'

# winnow_collect_log_file 
# based on the comment above regarding RAILS_ROOT being set incorrect I'll use 
# relative paths
logger_suffix = RAILS_ENV == 'test' ? 'test' : ""
WINNOW_COLLECT_LOG = File.join(RAILS_ROOT, 'log', "winnow_collect.log#{logger_suffix}")

# And now some Monkey Patching

# Patch CGI::unescapeHTML to ignore non-printable characters and not escape ampersands
# that are already part of an escape.  This is to better handle special characters in
# FeedTools
#  
class CGI
  def CGI.escapeHTML(string)    
    string.gsub(/&(?!((\w|\d)+|\#\d+|\#x[0-9A-F]+);)/, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;')    
  end
  
  def CGI.unescapeHTML(string)
    string.gsub(/&(.*?);/n) do
      match = $1.dup
      case match
      when /\Aamp\z/ni           then '&'
      when /\Aquot\z/ni          then '"'
      when /\Agt\z/ni            then '>'
      when /\Alt\z/ni            then '<'
      when /\A#0*(\d+)\z/n       then
        if Integer($1) < 128  # Change from 256 to 128
          Integer($1).chr
        else
          if Integer($1) < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
            [Integer($1)].pack("U")
          else
            "&##{$1};"
          end
        end
      when /\A#x([0-9a-f]+)\z/ni then
        if $1.hex < 128 # Change from 256 to 128
          $1.hex.chr
        else
          if $1.hex < 65536 and ($KCODE[0] == ?u or $KCODE[0] == ?U)
            [$1.hex].pack("U")
          else
            "&#x#{$1};"
          end
        end
      else
        "&#{match};"
      end
    end
  end
end

module UrlWithViewId
  def self.included(base)
    base.alias_method_chain :url_for, :view_id
  end
  
  def url_for_with_view_id(options = {}, *parameters_for_method_reference)
    if @view
      if options.kind_of? Hash
        options = { :view_id => @view.id }.update(options.symbolize_keys)
      elsif options.kind_of? String
        unless options.include?("view_id=")      
          if options.include?("?")
            options << "&view_id=#{@view.id}"
          else
            options << "?view_id=#{@view.id}"        
          end
        end
      end
    end
    
    url_for_without_view_id(options, *parameters_for_method_reference)
  end
end
ActionView::Base.send :include, UrlWithViewId
ActionController::Base.send :include, UrlWithViewId
