namespace :test do
  desc "Run stories"
  task :stories do
    system("ruby stories/all.rb")
  end
end

task :test do
  Rake::Task['test:stories'].invoke
end
