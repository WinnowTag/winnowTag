# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require 'rubygems'
require 'rake/gempackagetask'

# Generates a Gem file containing all the dependancies for Winnow
#
# Run with rake winnow:gem
namespace :winnow do 
  WINNOW_VERSION = '0.3.0'
  spec = Gem::Specification.new do |s|
      s.platform = Gem::Platform::RUBY
      s.summary = "Gem for Winnow."
      s.name = 'winnow-deps'
      s.version = WINNOW_VERSION
      s.requirements << 'MySQL 5.0'
      s.require_path = 'lib'
      s.files = ['lib/tasks/install.rake']
      s.description = <<-EOF
        A Gem for Winnow that includes all the dependencies.
      EOF
      s.add_dependency('hpricot', '0.4.59')
      s.add_dependency('feedtools', '>= 0.2.26')
      s.add_dependency('rails', '1.1.6')
      s.add_dependency('cached_model', '1.2.1')
      s.add_dependency('uuidtools', '1.0.0')
      s.add_dependency('capistrano', '>= 1.2.0')
      s.add_dependency('slave') #, '>= 1.2.0')
      s.add_dependency('daemons', '>= 1.0.3')
      s.add_dependency('uuidtools', '>= 1.0.0')
  end
    
  desc "Build a Gem for Winnow that depends on all Winnow's dependencies"
  Rake::GemPackageTask.new(spec) do |gem|
    gem.need_zip = true
    gem.need_tar = true
  end
  
  desc "Dump the corpus in the Bayes Cross Validation Format"
  task :cv_dump => [:environment, 'corpus'] do
    corpus_name = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    rm_f File.join('corpus', corpus_name)
    mkdir_p File.join('corpus', corpus_name)

    User.find(:all).each do |u|
      puts "Writing taggings for #{u.login}"
      File.open(File.join('corpus', corpus_name, "#{u.login}-taggings.csv"), 'w') do |f|
        u.taggings.each do |t|
          f << "#{t.tag},#{t.taggable_id},#{t.strength}\n"
        end
      end
    end
    
    puts "Writing Feed Items"
    FeedItem.each(:include => :feed_item_content) do |fi|
      File.open(File.join('corpus', corpus_name, "#{fi.id}.html"), 'w') do |f|
        f.write("<h1>#{fi.content.title}</h1>\n")
        f.write(fi.content.encoded_content)
      end
    end
  end
    
  directory 'corpus'
end

directory "tmp/imported_corpus"


namespace :test do
  task :functionals => "tmp/imported_corpus"
  
  desc "Run rcov on current app"
  task :rcov do
    test_dir    = "#{RAILS_ROOT}/test"
    dirs        = [ "#{test_dir}/functional/*.rb",
                    "#{test_dir}/integration/*.rb",
                    "#{test_dir}/unit/*.rb",
                    "#{test_dir}/unit/helpers/*.rb",]

    output_dir = (ENV['CC_BUILD_ARTIFACTS'] or 'test')
    command = "rcov --rails -o #{output_dir}/coverage"

    dirs.each do |dir|
      command += " #{dir}" unless Dir[dir].empty?
    end
    sh command
  end
  
  desc 'Test the classifier.'
  task :classifier do
    sh "cd vendor/bayes && rake"
  end
  
  desc 'Test all custom plugins'
  task :pw_plugins do
    %w(active_record_iterator winnow_feed).each do |plugin|
      cd "vendor/plugins/#{plugin}" do
        sh "rake"
      end
    end
  end
  
  namespace :db do
    desc "Replacement for db structure cloning that uses migrations for the test schema"
    task :initialize do
      ENV['RAILS_ENV'] = RAILS_ENV = 'test'   
      #Rake::Task['db:test:prepare'].invoke
      Rake::Task['db:migrate'].invoke
    end
  end
end

task :test => ['test:pw_plugins', 'test:classifier']

# Replace test task dependency on db:test:prepare with our own db:test:initialize
[:'test:recent', :'test:units', :'test:functionals', :'test:integration'].each do |task|
  Rake::Task[task].prerequisites.delete('db:test:prepare')
  Rake::Task[task].prerequisites << 'test:db:initialize'
end

desc "Task for CruiseControl.rb"
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  Rake::Task['test:db:initialize'].invoke
  Rake::Task['test'].invoke
  Rake::Task['spec'].invoke
  Rake::Task['test:rcov'].invoke
  # Rake::Task['test:selenium'].invoke
end
