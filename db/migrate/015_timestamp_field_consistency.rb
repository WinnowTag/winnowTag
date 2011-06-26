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

class TimestampFieldConsistency < ActiveRecord::Migration
  def self.up
    add_column "classifiers_users", "created_on", :datetime
    add_column "classifiers_tags", "created_on", :datetime
    add_column "feed_item_contents", "created_on", :datetime
    rename_column "feed_items", "time_retrieved", "created_on"
    rename_column "feeds", "time_last_retrieved", "updated_on"
    add_column "feeds", "created_on", :datetime
  end

  def self.down
    rename_column "feed_items", "created_on", "time_retrieved"
    remove_column "classifiers_tags", "created_on"
    remove_column "classifiers_users", "created_on"
    remove_column "feed_item_contents", "created_on"
    rename_column "feeds", "updated_on", "time_last_retrieved"
    remove_column "feeds", "created_on"
  end
end
