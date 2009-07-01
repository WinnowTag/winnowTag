# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require Rails.root.join("vendor/gems/selenium-client-1.2.14/lib/selenium/rake/tasks")
require Rails.root.join("vendor/gems/selenium-client-1.2.14/lib/selenium/configuration")

Selenium::Rake::RemoteControlStartTask.new do |rc|
  rc.background = true
  rc.wait_until_up_and_running = true
  # http://nexus.openqa.org/content/repositories/snapshots/org/seleniumhq/selenium/server/selenium-server/1.0-SNAPSHOT/
  rc.jar_file = File.join(File.dirname(__FILE__), '..', 'selenium-server.jar')
  rc.additional_args << "-singleWindow"
  rc.additional_args << "> /dev/null"
end

Selenium::Rake::RemoteControlStopTask.new do |rc|
end

require 'spec/rake/spectask'

desc 'Run acceptance tests for web application on default browser defined in config/selenium.yml'
Spec::Rake::SpecTask.new('selenium') do |t|
  path = ENV['CC_BUILD_ARTIFACTS'] || "./tmp"

  t.spec_opts = [
    "--colour",
    "--format=profile",
    "--format='Selenium::RSpec::SeleniumTestReportFormatter:#{path}/selenium-default.html'"
  ]

  t.spec_files = FileList['spec/selenium/*_spec.rb']
end

Selenium::Configuration.each do |configuration|
  desc "Run acceptance tests for web application on #{configuration} browser defined in config/selenium.yml"
  Spec::Rake::SpecTask.new("selenium:#{configuration}") do |t|
    path = ENV['CC_BUILD_ARTIFACTS'] || "./tmp"

    t.spec_opts = [
      "--colour",
      "--format=profile",
      "--format='Selenium::RSpec::SeleniumTestReportFormatter:#{path}/selenium-#{configuration}.html'"
    ]

    t.spec_files = FileList['spec/selenium/*_spec.rb']
  end
end

desc 'Run acceptance tests for web application on all browsers defined in config/selenium.yml'
task 'selenium:all' do
  Selenium::Configuration.each do |configuration|
    ENV['SELENIUM_CONFIGURATION'] = configuration
    Rake::Task["selenium:#{configuration}"].invoke
  end
end
