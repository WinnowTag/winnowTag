#!/usr/bin/env ruby

require "rubygems"
gem "ratom"
gem "grit"
require "atom"
require "atom/configuration"
require "grit"
require "net/http"
require "optparse"
require "fileutils"
require "cgi"
require 'addressable/uri'
require 'yaml'

include Grit

parser = OptionParser.new do |opts|
  opts.banner = <<BANNER
Backup all the training tags in a Winnow instance.

Usage: #{File.basename($0)} <tag-index-url> <output-directory>

Options are:

   tag-index-url      The URL to a tag index atom document in Winnow
   output-directory   The directory in which to create the backup.
BANNER

  opts.separator ""
  opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
  opts.parse!(ARGV)

  if ARGV.size != 2
    puts opts; exit
  end
end

tag_index_url = ARGV[0]
output = ARGV[1]

puts "Will backup tags from #{tag_index_url} to #{output}"

# "borrow" the classifier's credentials
credentials = YAML.load(File.read("config/hmac_credentials.yml"))['classifier']
access_id = credentials.keys.first
secret = credentials.values.first

unless File.exists?(output)
  Dir.mkdir(output)
end

FileUtils.cd(output) do 
  repo = begin
    Repo.new(output)
  rescue InvalidGitRepositoryError => e
    `cd #{output} && git init`
    Repo.new(output)
  end
    
  File.open("errors.txt", "w") do |errors|
    
    # First we grab the tag index and save it to index.xml
    index_file = "index.xml"
    tag_index = Atom::Feed.load_feed(URI.parse(tag_index_url), {
                    :hmac_access_id => access_id, 
                    :hmac_secret_key => secret
                  })
    File.open(index_file, "w") do |f|
      f << tag_index.to_xml
    end
  
    puts "Downloading #{tag_index.entries.size} tags"
  
    # Now for every tag in the index we need to fetch it and save it
    # in a file with a name produced from URI escaping the path 
    # component of the tag's id.
    #
    tag_index.entries.each do |entry|
      begin
        tag_training_url = entry.links.detect {|l| l.rel == "http://peerworks.org/classifier/training"}.href
        puts "Fetching #{entry.title} from #{tag_training_url}"
        tag_feed = Atom::Feed.load_feed(URI.parse(tag_training_url), {
                        :hmac_access_id => access_id, 
                        :hmac_secret_key => secret
                      })
                      
        user, _t, tag = Addressable::URI.parse(entry.id).path.sub(/^\//, "").split("/")
        FileUtils.mkdir_p(CGI.escape(user))
        tag_filename = File.join(CGI.escape(user), CGI.escape(tag))
        
        File.open(tag_filename, "w") do |f|
          f << tag_feed.to_xml
        end
        
        repo.add(tag_filename)
      rescue Exception => e
        errors << "#{e}\n"
        errors.flush
      end
    end

    repo.add(index_file)
  end
  
  repo.add("errors.txt")
  repo.commit_index("Committed tag changes for #{Time.now}")
end
