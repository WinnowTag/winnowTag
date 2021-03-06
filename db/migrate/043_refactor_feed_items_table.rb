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

class RefactorFeedItemsTable < ActiveRecord::Migration
  def self.up
    create_table :feed_item_xml_data do |t|
      t.column :xml_data, :longtext
      t.column :created_on, :datetime      
    end
    
    execute <<-END_SQL
      INSERT
        INTO feed_item_xml_data (id, xml_data, created_on)
        SELECT id, xml_data, NOW() from feed_items;
    END_SQL
    
    remove_column :feed_items, :xml_data
  end

  def self.down
    execute "alter table feed_items add column xml_data longtext;"
    execute <<-END_SQL
      UPDATE
        feed_items, feed_item_xml_data
      SET
        feed_items.xml_data = feed_item_xml_data.xml_data
      WHERE
        feed_items.id = feed_item_xml_data.id;
    END_SQL
    drop_table :feed_item_xml_data
  end
end
