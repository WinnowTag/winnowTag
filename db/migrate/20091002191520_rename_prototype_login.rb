# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class RenamePrototypeLogin < ActiveRecord::Migration
  
  class User < ActiveRecord::Base; end
  
  def self.up
    User.find_each(:conditions => ["login LIKE ?", "%*%"]) do |user|
      begin
        user.login = user.login.gsub("*", "")
        user.save!
      rescue => e
        say "Error renaming login for user ##{user.id} - #{e.class.name}: #{e.message}"
      end
    end
  end

  def self.down
    # nothing to do
  end
end
