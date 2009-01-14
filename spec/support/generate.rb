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
    unique_id = unique_id_for(:comment)
    
    Comment.new(attributes.reverse_merge(
      :body => "Comment #{unique_id}",
      :user => Generate.user!,
      :tag => Generate.tag!
    ))
  end
  
  def self.user!(attributes = {})
    unique_id = unique_id_for(:user)
    
    User.create!(attributes.reverse_merge(
      :login => "user_#{unique_id}",
      :email => "user_#{unique_id}@example.com",
      :crypted_password => BCrypt::Password.create(attributes.delete(:password) || "password"),
      :firstname => "John",
      :lastname => "Doe",
      :time_zone => "UTC",
      :activated_at => Time.now
    ))
  end
  
  def self.admin!(attributes = {})
    admin = self.user!(attributes)
    admin.has_role("admin")
    admin
  end
  
  def self.tag(attributes = {})
    unique_id = unique_id_for(:tag)
    
    Tag.new(attributes.reverse_merge(
      :name => "Tag #{unique_id}",
      :user => Generate.user!
    ))
  end

  def self.tag!(attributes = {})
    unique_id = unique_id_for(:tag)
    
    Tag.create!(attributes.reverse_merge(
      :name => "Tag #{unique_id}",
      :user => Generate.user!
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

  def self.feed_item!(attributes = {})
    unique_id = unique_id_for(:feed_item)
    
    FeedItem.create!(attributes.reverse_merge(
      :feed => self.feed!,
      :link => "http://example.com/#{unique_id}",
      :title => "Feed Item #{unique_id}",
      :author => "Author #{unique_id}",
      :collector_link => "http://collector.mindloom.org/feed_items/#{unique_id}.atom",
      :uri => "uri:FeedItem#{unique_id}"
    ))
  end
end