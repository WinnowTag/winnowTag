# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Generate
  UniqueId = Hash.new(0)

  def self.unique_id_for(key)
    UniqueId[key] += 1
  end
  
  def self.comment(attributes = {})
    Comment.new(:tag_id => 1, :user_id => 1, :body => "Example body")
  end
  
  def self.user!(attributes = {})
    unique_id = unique_id_for(:user)
    
    User.create!(attributes.reverse_merge(
      :login => "user_#{unique_id}",
      :email => "user_#{unique_id}@example.com",
      :password => "password",
      :password_confirmation => "password",
      :firstname => "John",
      :lastname => "Doe",
      :time_zone => "UTC",
      :activated_at => Time.now
    ))
  end
  
  def self.feed!(attributes = {})
    unique_id = unique_id_for(:feed)
    
    Feed.create!(attributes.reverse_merge(
      :via => "http://#{unique_id}.example.com/feed.atom",
      :alternate => "http://#{unique_id}.example.com",
      :title => "Feed #{unique_id}",
      :uri => "uri:Feed#{unique_id}"
    ))
  end
end