# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../vendor/plugins/rspec/lib/spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov_for_cc') do |t|
  t.spec_files = FileList['spec/controllers/**/*.rb', 'spec/helpers/*.rb', 'spec/models/*.rb', 'spec/views/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
  t.rcov_dir = (ENV['CC_BUILD_ARTIFACTS'] || ".") + '/coverage'
end

desc "Task for CruiseControl.rb"
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  Rake::Task['gems:build'].invoke
  Rake::Task['db:migrate'].invoke
  
  Rake::Task['spec:code'].invoke
  Rake::Task['spec:controllers'].invoke
  Rake::Task['spec:helpers'].invoke
  Rake::Task['spec:models'].invoke
  Rake::Task['spec:views'].invoke
  Rake::Task['features'].invoke
end

task :cruise_with_selenium do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  Rake::Task['gems:build'].invoke
  Rake::Task['db:migrate'].invoke
  Rake::Task['assets:clean'].invoke
  system "touch tmp/restart.txt"
  
  Rake::Task['spec:code'].invoke
  Rake::Task['spec:controllers'].invoke
  Rake::Task['spec:helpers'].invoke
  Rake::Task['spec:models'].invoke
  Rake::Task['spec:views'].invoke
  Rake::Task['features'].invoke
  Rake::Task['selenium:rc:start'].invoke
  Rake::Task['selenium'].invoke
  Rake::Task['selenium:rc:stop'].invoke

  # TODO: This needs to span specs, features, and selenium
  # Rake::Task['rcov_for_cc'].invoke
end
