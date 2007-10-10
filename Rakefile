# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

def do_not_show_test_names_when_running_tests 
  Rake::TestTask.class_eval do
    alias_method :crufty_define, :define
    def define
      @verbose = false
      crufty_define
    end
  end
end

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

do_not_show_test_names_when_running_tests

require 'tasks/rails'
