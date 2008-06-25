# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
namespace :test do
  desc "Run stories"
  task :stories do
    system("ruby stories/all.rb")
  end
end

task :test do
  Rake::Task['test:stories'].invoke
end
