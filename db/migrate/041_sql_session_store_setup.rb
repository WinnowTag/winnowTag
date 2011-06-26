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

class SqlSessionStoreSetup < ActiveRecord::Migration
  class Session < ActiveRecord::Base; end

  def self.up
    c = ActiveRecord::Base.connection
    if c.tables.include?('sessions')
      if (columns = Session.column_names).include?('sessid')
        rename_column :sessions, :sessid, :session_id
      else
        add_column :sessions, :session_id, :string unless columns.include?('session_id')
        add_column :sessions, :data, :text unless columns.include?('data')
        if columns.include?('created_on')
          rename_column :sessions, :created_on, :created_at
        else
          add_column :sessions, :created_at, :timestamp unless columns.include?('created_at')
        end
        if columns.include?('updated_on')
          rename_column :sessions, :updated_on, :updated_at
        else
          add_column :sessions, :updated_at, :timestamp unless columns.include?('updated_at')
        end
      end
    else
      create_table :sessions, :options => 'ENGINE=MyISAM' do |t|
        t.column :session_id, :string
        t.column :data,       :text
        t.column :created_at, :timestamp
        t.column :updated_at, :timestamp
      end
      add_index :sessions, :session_id, :name => 'session_id_idx'
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
