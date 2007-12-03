# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.
require 'mongrel_cluster/recipes'

# Function to get the subversion repository for the working directory
def get_working_directory_repository
  info = `svn info #{File.join(File.dirname(__FILE__), '..')}`
  
  if info =~ /URL: (.*)/
    puts $1
    return $1
  else
    raise "Could not discover URL from #{info}"
  end
end

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "winnow"
set :use_sudo, false
set :checkout, "checkout"

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

if ENV['STAGE'] == 'seangeo' or ENV['STAGE'] == 'mh'
  set :subdomain, ENV['STAGE']
  set :domain, "#{ENV['STAGE']}.wizztag.org"
  set :repository, get_working_directory_repository
  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true
  set :deploy_to, "/home/#{ENV['STAGE']}/www/#{ENV['STAGE']}.deploy"
  set :user, ENV['STAGE']
elsif ENV['STAGE'] =~ /^set[\d]$/ or %w(trunk alpha).include?(ENV['STAGE'])
  if ENV['STAGE'] == 'alpha'
    set :repository, "http://svn.winnow.peerworks.org/tags/winnow_ALPHA"
  elsif ENV['STAGE'] == 'trunk'
    set :repository, "http://svn.winnow.peerworks.org/trunk/winnow"
  else
    set :repository, "http://svn.winnow.peerworks.org/tags/winnow_M3"
  end
  
  set :subdomain, ENV['STAGE']
  set :domain, "#{subdomain}.wizztag.org"
  role :web, domain
  role :app, domain
  role :db, domain, :primary => true
  set :deploy_to, "/home/winnow/www/#{subdomain}.deploy"
  set :user, 'winnow'
end

set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
# set :deploy_to, "/path/to/app" # defaults to "/u/apps/#{application}"
# set :user, "flippy"            # defaults to the currently logged in user
# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway

# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
ssh_options[:port] = 65000

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

# Tasks may take advantage of several different helper methods to interact
# with the remote server(s). These are:
#
# * run(command, options={}, &block): execute the given command on all servers
#   associated with the current task, in parallel. The block, if given, should
#   accept three parameters: the communication channel, a symbol identifying the
#   type of stream (:err or :out), and the data. The block is invoked for all
#   output from the command, allowing you to inspect output and act
#   accordingly.
# * sudo(command, options={}, &block): same as run, but it executes the command
#   via sudo.
# * delete(path, options={}): deletes the given file or directory from all
#   associated servers. If :recursive => true is given in the options, the
#   delete uses "rm -rf" instead of "rm -f".
# * put(buffer, path, options={}): creates or overwrites a file at "path" on
#   all associated servers, populating it with the contents of "buffer". You
#   can specify :mode as an integer value, which will be used to set the mode
#   on the file.
# * render(template, options={}) or render(options={}): renders the given
#   template and returns a string. Alternatively, if the :template key is given,
#   it will be treated as the contents of the template to render. Any other keys
#   are treated as local variables, which are made available to the (ERb)
#   template.

task :package_assets, :role => :web do
  run "cd #{release_path} && rake RAILS_ENV=production asset:packager:build_all"
end

task :config_collector do
  put("http://collector.wizztag.org", "#{shared_path}/collector.conf")
end

task :after_update_code do
  run "ln -s #{shared_path}/tmp #{release_path}/tmp"
  run "ln -s #{shared_path}/exported_corpus #{release_path}/public/exported_corpus"
  run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
  run "ln -s #{shared_path}/mongrel_cluster.yml #{release_path}/config/mongrel_cluster.yml"
  run "ln -s #{shared_path}/collector.conf #{release_path}/config/collector.conf"
end

task :before_symlink do
  package_assets
end

desc "Notify the list of deployment"
task :after_deploy do
  mail_comment = comment rescue mail_comment = "None provided."
  # Run it on the server so we know we have a good email configuration
  run %Q(cd #{current_path} && script/runner 'Notifier.deliver_deployed("http://#{domain}", "#{repository}", "#{revision}", "#{ENV['USER']}", "#{mail_comment}")')
end

task :after_setup do
  dbyaml =<<-END
production:
  adapter: mysql
  database: #{subdomain}
  host: localhost
  username: #{user}
  password: #{ENV['db_pass']}
  
development:
  adapter: mysql
  database: #{subdomain}
  host: localhost
  username: #{user}
  password: #{ENV['db_pass']}

END

  bgyaml =<<-END
---
cwd: #{current_path}
user: #{user}
port: #{ENV['bg_port']}
timer_sleep: 60
load_rails: true
environment: development
host: localhost
database_yml: config/database.yml
acl:
  deny: all
  allow: localhost 127.0.0.1
  order: deny,allow
END

  cluster_config =<<-END
--- 
user: #{user}
group: users
cwd: #{current_path}
port: #{ENV['mg_port']}
environment: production
address: 127.0.0.1
pid_file: log/mongrel.pid
servers: 4
END

  put(dbyaml, "#{shared_path}/database.yml")
  put(bgyaml, "#{shared_path}/backgroundrb.yml")
  put(cluster_config, "#{shared_path}/mongrel_cluster.yml")
  
  run "mkdir -p #{shared_path}/tmp"
  run "mkdir -p #{shared_path}/exported_corpus"
end
