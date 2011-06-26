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

namespace :corpus do
  directory 'corpus/item_cache/items'
  directory 'corpus/tags'
  
  task 'corpus/item_cache/catalog.db' do
    catalog_file = 'corpus/item_cache/catalog.db'
    unless File.exists?(catalog_file)
      schema_location = '/usr/local/share/classifier/initial_schema.sql'
      if File.exists?(schema_location)
        system("cat #{schema_location} | sqlite3 #{catalog_file}")
        puts "Database created!"
      else
        puts "Could not find the initial schema file at #{schema_location}."
        puts "You can try creating the database using 'classifier --db #{catalog_file} --create-db'"
        exit(1)
      end
    end
  end
  
  task :dump_item_cache => [:environment, 'corpus/item_cache/items', 'corpus/item_cache/catalog.db'] do
    gem 'progressbar'
    require 'progressbar'
    gem 'sqlite3-ruby'
    require 'sqlite3'
    sqlite = SQLite3::Database.open("corpus/item_cache/catalog.db")
    pb = ProgressBar.new("Items", FeedItem.count)
    
    FeedItem.find(:all).each do |fi|
      atom = fi.to_atom
      sqlite.execute("insert or ignore into feeds (id, title) values (#{fi.feed.id}, :title)", :title => fi.feed.title)
      sqlite.execute("insert into entries (id, full_id, feed_id, updated, created_at) " +
                     "values (:id, :full_id, :feed_id, julianday(:updated), julianday(:created_at));",
                      :id => fi.id, :full_id => atom.id, :feed_id => fi.feed.id,
                      :updated => atom.updated.strftime('%Y-%m-%d %H:%M:%S'),
                      :created_at => fi.created_on.strftime('%Y-%m-%d %H:%M:%S'))
      File.open("corpus/item_cache/items/#{fi.id}.atom", 'w+') do |out|
        out << fi.to_atom.to_xml
      end
      pb.inc
    end
    pb.finish
  end
  
  task :dump_tags => [:environment, 'corpus/tags'] do
    gem 'progressbar'
    require 'progressbar'
    pb = ProgressBar.new("Tags", Tag.count)
    
    Tag.find(:all).each do |tag|
      File.open("corpus/tags/#{tag.user.login}-#{tag.name}.atom", "w+") do |out|
        out << tag.to_atom(:training_only => true, :base_uri => 'http://localhost', :limit => 10000).to_xml
      end
      
      pb.inc
    end
    
    pb.finish
  end
  
  desc "dump the corpus"
  task :dump => [:dump_item_cache, :dump_tags] 
end