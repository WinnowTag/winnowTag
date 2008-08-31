# Configuration for the Fiveruns manage plugin.
#
# This is loaded by the plugin, which expects it to be at config/manage.rb
#
Fiveruns::Manage::Plugin.configure do |config|
 config.environments = %w(production)
 config.report_environments = %w(production)
 config.report_interval = 25
end