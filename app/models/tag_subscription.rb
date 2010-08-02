# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a User subscribing to a Tag. In other words, the User wants
# to see content from this Tag.
class TagSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :user_id, :tag_id

  def tag_archived(original_creator)
    update_attribute(:original_creator, original_creator);
    update_attribute(:original_creator_timestamp, Time.now.utc);
  end

  def tag_renamed(old_name, new_name)
    if !original_name
      update_attribute(:original_name, old_name);
      update_attribute(:original_name_timestamp, Time.now.utc);
    elsif original_name == new_name
      clear_original_name;
    end
  end

  def clear_original_creator
    update_attribute(:original_creator, nil);
    update_attribute(:original_creator_timestamp, nil);
  end

  def clear_original_name
    update_attribute(:original_name, nil);
    update_attribute(:original_name_timestamp, nil);
  end
end
