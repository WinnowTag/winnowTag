# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

#config.log_level = :info

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# In the evaluation environment, the database is specified by ENV['EVAL_DB'].
# So here we get the config for EVAL_DB from the evaluation_configs defined
# in database.yml and set it to evaluation on the root of the configurations hash.
# 
# We need to overrive the database_configuration method of the config object in order
# to do it.
class << config
  alias_method :old_database_configuration, :database_configuration
  
  def database_configuration
    raise ArgumentError, 'You must defined EVAL_DB when running in evaluation mode.' unless ENV['EVAL_DB']
    db_config = old_database_configuration
    if db_config['evaluation_configs'][ENV['EVAL_DB']].nil?
      raise ArgumentError, "#{ENV['EVAL_DB']} does not exist as a child of evaluation_configs in database.yml" 
    end

    db_config['evaluation'] = db_config['evaluation_configs'][ENV['EVAL_DB']]
    db_config
  end
end

