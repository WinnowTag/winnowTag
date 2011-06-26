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
