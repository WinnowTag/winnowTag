$:.unshift(RAILS_ROOT + '/vendor/gems/cucumber-0.1.14/lib')
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty"
end
task :features => 'db:test:prepare'