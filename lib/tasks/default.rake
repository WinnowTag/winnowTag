# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
task :default do
  Rake::Task['spec'].invoke
  Rake::Task['features'].invoke
end

task :all do
  begin
    Rake::Task['spec'].invoke
    Rake::Task['features'].invoke
    Rake::Task['selenium:rc:start'].invoke
    Rake::Task['selenium'].invoke
  ensure
    Rake::Task['selenium:rc:stop'].invoke
    Rake::Task['assets:clean'].invoke
  end
end