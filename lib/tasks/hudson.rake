# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

task :selenium_for_hudson do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  
  Rake::Task['assets:clean'].invoke
  # system "touch tmp/restart.txt"
  system "mongrel_rails start -e test -p 3000 -d"
  at_exit {
    system "mongrel_rails stop"
  }
  Rake::Task['selenium:all'].invoke
end