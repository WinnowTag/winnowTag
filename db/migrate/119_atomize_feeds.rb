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

class AtomizeFeeds < ActiveRecord::Migration
  def self.up
    # remove auto-increment from feeds
    execute "alter table feeds modify column id integer not null;"   
    # remove_column :feeds, :is_duplicate
    remove_column :feeds, :active
    rename_column :feeds, :link, :alternate
    rename_column :feeds, :url, :via
    add_column :feeds, :collector_link, :string
          
    # add atom timestamp columns, these are independent from the internal updated_on and created_on columns
    add_column :feeds, :updated, :datetime
    add_column :feeds, :published, :datetime
    execute "update feeds set updated = updated_on and published = created_on;"
  end

  def self.down
    raise IrreversibleMigration
  end
end
