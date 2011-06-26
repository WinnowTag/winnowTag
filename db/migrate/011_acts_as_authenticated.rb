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

class ActsAsAuthenticated < ActiveRecord::Migration
  def self.up
    remove_column "users", "role"
    remove_column "users", "deleted"
    remove_column "users", "token_expiry"
    remove_column "users", "verified"
    rename_column "users", "delete_after", "deleted_at"
    rename_column "users", "salted_password", "crypted_password"
    rename_column "users", "security_token", "activation_code"
    add_column "users", "activated_at", :datetime
    add_column "users", "remember_token", :string
    add_column "users", "remember_token_expires_at", :datetime
  end

  def self.down
    remove_column "users", "remember_token"
    remove_column "users", "remember_token_expires_at"
    remove_column "users", "activated_at"
    rename_column "users", "activation_code", "security_token"
    rename_column "users", "deleted_at", "delete_after"
    rename_column "users", "crypted_password", "salted_password"
    add_column "users", "role", :string
    add_column "users", "deleted", :integer
    add_column "users", "token_expiry", :datetime
    add_column "users", "verified", :integer
    
    # verify all
    User.find(:all).each do |u|
      u.verified = true
      u.save
    end
  end
  
  class User < ActiveRecord::Base; end
end
