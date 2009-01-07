# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ValidAttributes
  UniqueId = Hash.new(0)

  def unique_id_for(key)
    UniqueId[key] += 1
  end

  def valid_feed_item_attributes(attributes = {})
    unique_id = unique_id_for(:feed_item)
    { :link => "http://#{unique_id}.example.com",
      :uri => "uri:uuid:#{unique_id}"
    }.merge(attributes)
  end
  
  def valid_feed_attributes(attributes = {})
    unique_id = unique_id_for(:feed)
    { :via => "http://#{unique_id}.example.com/index.xml",
      :alternate => "http://#{unique_id}.example.com",
      :title => "#{unique_id} Example",
      :feed_items_count => 0,
      :updated_on => Time.now,
      :duplicate_id => nil,
      :uri => "uri:#{unique_id}"
    }.merge(attributes)
  end
  
  def valid_user_attributes(attributes = {})
    unique_id = unique_id_for(:user)
    { :login => "user_#{unique_id}",
      :email => "user_#{unique_id}@example.com",
      :password => "password",
      :password_confirmation => "password",
      :firstname => "John_#{unique_id}",
      :lastname => "Doe_#{unique_id}",
      :time_zone => "UTC",
      :activated_at => Time.now
    }.merge(attributes)
  end
  
  def valid_tag_attributes(attributes = {})
    unique_id = unique_id_for(:tag)
    { :name => "Tag #{unique_id}",
      :user_id => unique_id
    }.merge(attributes)
  end
  
  def valid_invite_attributes(attributes = {})
    unique_id = unique_id_for(:invite)
    { :email => "user_#{unique_id}@example.com"
    }.merge(attributes)
  end
  
  def valid_tag_usage_attributes(attributes = {})
    { :tag_id => "1"
    }.merge(attributes)
  end
end