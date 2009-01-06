# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
def valid_user_attributes(attributes = {})
  unique_id = rand(100000)
  { :login => "user_#{unique_id}",
    :email => "user_#{unique_id}@example.com",
    :password => "password",
    :password_confirmation => "password",
    :firstname => "John_#{unique_id}",
    :lastname => "Doe_#{unique_id}",
    :activated_at => Time.now
  }.merge(attributes)
end

def valid_feed_attributes(attributes = {})
  unique_id = rand(100000)
  { :via => "http://#{unique_id}.example.com/index.xml",
    :alternate => "http://#{unique_id}.example.com",
    :title => "#{unique_id} Example",
    :feed_items_count => 0,
    :updated_on => Time.now,
    :duplicate_id => nil,
    :uri => "uri:#{unique_id}"
  }.merge(attributes)
end
