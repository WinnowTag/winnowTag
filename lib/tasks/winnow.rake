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
    FeedItem.find(:all, :include => :content).each do |fi|
      File.open(File.join('corpus', corpus_name, "#{fi.id}.html"), 'w') do |f|
        f.write("<h1>#{fi.content.title}</h1>\n")
        f.write(fi.content.encoded_content)
      end
    end
  end
    
  directory 'corpus'
end
