# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
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