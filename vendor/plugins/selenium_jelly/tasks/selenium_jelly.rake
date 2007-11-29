namespace :test do
  desc 'Run the Selenium tests in test/selenium'
  Rake::TestTask.new(:selenium => 'db:test:prepare') do |t|
    t.libs << 'test'
    t.pattern = 'test/selenium/**/*_test.rb'
    t.verbose = true
  end
end
