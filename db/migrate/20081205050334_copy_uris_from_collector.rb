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



class CopyUrisFromCollector < ActiveRecord::Migration
  # Here we copy the URIs from the collector into Winnow. This needs
  # to be done to ensure that global uri are bound to the same feed
  # in both the collector and Winnow.  Once this is done the id columns
  # in the collector and winnow will be considered separate and
  # a feed's collector assigned uri will be the identifying attribute
  # for a feed.
  #
  #
  # This migration requires the winnow DB user to have access
  # to the collector database. This should be a simple temporary
  # permission change.  If there is a case where it isn't we may
  # need some additional code to handle importing the new id map.
  #
  def self.up
    say "This migration requires access to the collector database to copy across feed uris."
    say "If you don't have the collector database setup you can just skip this."

    if execute("SHOW DATABASES LIKE 'collector'").num_rows > 0
      execute "UPDATE feeds SET uri = (SELECT uri FROM collector.feeds WHERE collector.feeds.url = feeds.via)"
    end
  end

  def self.down
  end
end
