# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# This is a key pair obtained for 'trunk.mindloom.org' but set to be global so it will work for development.
ENV['RECAPTCHA_PUBLIC_KEY'] = '6Lcmm7sSAAAAAPo5dZt5oyrPHZaxh6dvW32mo91s'
ENV['RECAPTCHA_PRIVATE_KEY'] = '6Lcmm7sSAAAAAFhrlLZqav4deap86NpIXJzk7COT'

