# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AddOriginalNameAndCreatorToSubscription < ActiveRecord::Migration
  def self.up
    add_column :tag_subscriptions, :original_name, :string
    add_column :tag_subscriptions, :original_name_timestamp, :datetime
    add_column :tag_subscriptions, :original_creator, :string
    add_column :tag_subscriptions, :original_creator_timestamp, :datetime
  end

  def self.down
    remove_column :tag_subscriptions, :original_name
    remove_column :tag_subscriptions, :original_name_timestamp
    remove_column :tag_subscriptions, :original_creator
    remove_column :tag_subscriptions, :original_creator_timestamp
  end
end
