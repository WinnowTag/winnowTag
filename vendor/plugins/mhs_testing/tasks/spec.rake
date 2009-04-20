require 'selenium/rake/tasks'

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
  file = ENV['SELENIUM_CONFIGURATION'] || "acceptance_tests_report"

  t.spec_opts = [
    "--colour",
    "--format=profile",
    "--format='Selenium::RSpec::SeleniumTestReportFormatter:#{path}/#{file}.html'"
  ]

  t.spec_files = FileList['spec/selenium/*_spec.rb']
end

desc 'Run acceptance tests for web application on all browsers defined in config/selenium.yml'
task 'selenium:all' do
  Selenium::Configuration.each do |configuration|
    ENV['SELENIUM_CONFIGURATION'] = configuration
    Rake::Task["selenium"].invoke
  end
end

