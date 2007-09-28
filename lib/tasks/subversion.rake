# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Some helpers for common subversion tasks
namespace :svn do 
  
  desc "Create and switch to a bug fix branch"
  task :bugfix do
    if ENV['bug'].nil?
      puts "You need to specify a Ticket number using bug=#" 
    else
      bug = ENV['bug']
      create_branch('BUG', bug)
    end
  end
  
  desc "Create and switch to a classifier enhancement branch"
  task :class_exp do 
    if ENV['ticket'].nil?
      puts "You need to specify a Ticket number using ticket=#"
    else
      ticket = ENV['ticket']
      create_branch('CLASS_EXP', ticket)
    end
  end
  
  
  def create_branch(type, id)
    current_url = get_current_url
    
    if current_url.nil? or current_url.empty?
      puts "This only works in an SVN working directory."
    elsif current_url =~ /.*\/(.+)/
      base = $1
      sh "svn copy #{current_url} http://svn.winnow.peerworks.org/tags/PRE-#{type}#{id} -m \"Create PRE tag for ##{id}\"" 
      sh "svn copy #{current_url} http://svn.winnow.peerworks.org/branches/#{base}-#{type}#{id} -m \"Create branch for ##{id}\"" 
      sh "svn switch http://svn.winnow.peerworks.org/branches/#{base}-#{type}#{id}"
    else
      puts "Couldn't work out base folder from #{current_url}"
    end
  end
  
  def get_current_url
    svn_info = `svn info`
    if svn_info =~ /URL: (.*)$/
      return $1    
    end
  end
end
