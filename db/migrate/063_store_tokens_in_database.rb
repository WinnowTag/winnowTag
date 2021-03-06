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

class StoreTokensInDatabase < ActiveRecord::Migration
  def self.up
    create_table :tokens, :options => 'ENGINE=MyISAM' do |t|
      t.column :token, :string
    end
    
    token_file = File.expand_path(File.join(RAILS_ROOT, 'log', 'tokens.log'))
    
    if File.exists?(token_file)
      say("About to load #{token_file} into database. This could take a while...")
      execute("load data infile '#{token_file}' into table tokens fields terminated by ',';")
      say("#{token_file} has been loaded into the database.  You can delete it but reversing"+
          " this migration won't recreate it, so make sure you don't need it first.")
    end
  end

  def self.down
    drop_table :tokens
  end
end
