$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:features_for_ci) do |t|
    rm_rf("cucumber")
    mkdir("cucumber")
    t.cucumber_opts = "--format html > cucumber/features.html"
  end

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty"
  end
  task :features => 'db:test:prepare'
  task :features_for_ci => 'db:test:prepare'
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
