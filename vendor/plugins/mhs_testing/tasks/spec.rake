# TODO: How can I get around this?
require File.join(Rails.root, 'vendor/gems/selenium-client-1.2.14/lib', 'selenium/rake/tasks')
Selenium::Rake::RemoteControlStartTask.new do |rc|
  rc.background = true
  rc.wait_until_up_and_running = true
  rc.jar_file = File.join(File.dirname(__FILE__), '..', 'selenium-server.jar')
  rc.additional_args << "-singleWindow"
  rc.additional_args << "> /dev/null"
end

Selenium::Rake::RemoteControlStopTask.new do |rc|
end

# TODO: How can I get around this?
require File.join(Rails.root, 'vendor/gems/rspec-1.2.2/lib', 'spec/rake/spectask')
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

