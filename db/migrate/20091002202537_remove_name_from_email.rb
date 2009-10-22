# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RemoveNameFromEmail < ActiveRecord::Migration
  
  class User < ActiveRecord::Base; end
  
  def self.up
    regex = /"?(\w+) ([^"]+)"? <(.+)>/i
    User.find_each(:conditions => ["email LIKE ?", "%<%"]) do |user|
      begin
        if md = regex.match(user.email)
          user.email = md[3]
          user.firstname = md[1] if user.firstname.blank?
          user.lastname = md[2] if user.lastname.blank?
          
          changes = user.changes
          user.save!
          
          say "User ##{user.id} changes: #{changes.inspect}"
        end
      rescue => e
        say "Error removing name from email for user ##{user.id} - #{e.class.name}: #{e.message}"
      end
    end
  end

  def self.down
    # nothing to do
  end
end
