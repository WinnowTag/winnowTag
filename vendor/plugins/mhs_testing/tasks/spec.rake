# TODO: How can I get around this?
require File.join(Rails.root, 'vendor/gems/selenium-client-1.2.14/lib', 'selenium/rake/tasks')
Selenium::Rake::RemoteControlStartTask.new do |rc|
  rc.timeout_in_seconds = 3 * 60
  rc.background = true
  rc.wait_until_up_and_running = true
  rc.jar_file = File.join(File.dirname(__FILE__), '..', 'selenium-server.jar')
  rc.additional_args << "-singleWindow"
  rc.additional_args << "> /dev/null"
end

Selenium::Rake::RemoteControlStopTask.new do |rc|
  rc.timeout_in_seconds = 3 * 60
end

# TODO: How can I get around this?
require File.join(Rails.root, 'vendor/gems/rspec-1.1.11/lib', 'spec/rake/spectask')
desc 'Run acceptance tests for web application'
Spec::Rake::SpecTask.new('selenium') do |t|
  t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/selenium_spec.opts\""]
  path = ENV['CC_BUILD_ARTIFACTS'] || "./tmp"
  t.spec_opts << "--format='Selenium::RSpec::SeleniumTestReportFormatter:#{path}/acceptance_tests_report.html'"
  t.spec_files = FileList['spec/selenium/*_spec.rb']
end

