# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.


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
