# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require Rails.root.join("vendor/gems/selenium-client-1.2.14/lib/selenium/rake/tasks")
require Rails.root.join("vendor/gems/selenium-client-1.2.14/lib/selenium/configuration")

Selenium::Rake::RemoteControlStartTask.new do |rc|
  rc.background = true
  rc.wait_until_up_and_running = true
  # http://nexus.openqa.org/content/repositories/snapshots/org/seleniumhq/selenium/server/selenium-server/1.0-SNAPSHOT/
  rc.jar_file = Rails.root.join("vendor/plugins/mhs_testing/selenium-server.jar")
  rc.additional_args << "-singleWindow"
  rc.additional_args << "> /dev/null"
end

Selenium::Rake::RemoteControlStopTask.new do |rc|
end

# Don't create these tasks if running rake gems:* since it causes rspec to load before
# the configured gems are loaded.
#
unless ARGV.any? {|a| a =~ /^gems/}
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
    task "selenium:#{configuration}" do
      ENV['SELENIUM_CONFIGURATION'] = configuration
      Rake::Task["selenium:#{configuration}:spec"].invoke
    end

    Spec::Rake::SpecTask.new("selenium:#{configuration}:spec") do |t|
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
      puts "Running Selenium tests in #{configuration}"
      Rake::Task["selenium:#{configuration}"].invoke
    end
  end
end