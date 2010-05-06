# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "winnow"
set :use_sudo, false

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

default_run_options[:pty] = true
set :scm, 'git'
set :scm_verbose, true
set :repository, 'git@github.com:WinnowTag/winnowTag.git'
set :deploy_via, :remote_cache
set :group, "mongrels"

task :beta do
  set :deploy_to, "/home/peerworks/winnow.deploy"
  set :user, 'peerworks'
  set :branch, "beta" unless exists?(:branch)
  set :rails_env, "production"

  role :web, "winnow01.mindloom.org"
  role :web, "winnow02.mindloom.org"
  role :app, "winnow01.mindloom.org"
  role :app, "winnow02.mindloom.org"
  role :db,  "db01.c43900.blueboxgrid.com", :primary => true
end

task :trunk do
  set :deploy_to, "/home/mindloom/winnow.deploy"
  set :user, 'mindloom'
  set :domain, 'trunk.mindloom.org'
  set :branch, "master" unless exists?(:branch)
  set :rails_env, "trunk"

  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true
end

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
# ssh_options[:port] = 65000

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

task :config_collector do
  put("http://collector.mindloom.org", "#{shared_path}/collector.conf")
end

task :copy_config do
  run "ln -s #{shared_path}/tmp #{release_path}/tmp"
  run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
  run "ln -s #{shared_path}/collector.conf #{release_path}/config/collector.conf"
  run "ln -s #{shared_path}/classifier-client.conf #{release_path}/config/classifier-client.conf"
  run "ln -s #{shared_path}/hmac_credentials.yml #{release_path}/config/hmac_credentials.yml"
end


desc "Notify the list of deployment"
task :send_notification do
  mail_comment = comment rescue mail_comment = "None provided."
  # Run it on the server so we know we have a good email configuration
  run %Q(cd #{current_path} && script/runner -e #{rails_env} 'Notifier.deliver_deployed("http://#{domain}", "#{repository}", "#{revision}", "#{ENV['USER']}", "#{mail_comment}")')
end

after 'deploy:update_code', :copy_config
after :deploy, :send_notification

namespace :gems do
  task :build do  
    rake = fetch(:rake, "rake")
    run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} gems:build"
  end
end
after "deploy:update_code", "gems:build"

namespace :deploy do
  [:start, :stop, :restart, :status].each do |t|
    task t, :roles => :app do
      sudo "god #{t.to_s} #{group}"
    end
  end
end
