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

class Generate
  UniqueId = Hash.new(0)

  def self.unique_id_for(key)
    UniqueId[key] += 1
  end
  
  def self.invite(attributes = {})
    unique_id = unique_id_for(:invite)
    
    Invite.new(attributes.reverse_merge(
      :email => "user_#{unique_id}@example.com"
    ))
  end
  
  def self.invite!(attributes = {})
    returning self.invite(attributes) do |invite|
      invite.save!
    end 
  end
  
  def self.comment(attributes = {})
    unique_id = unique_id_for(:comment)
    
    Comment.new(attributes.reverse_merge(
      :body => "Comment #{unique_id}",
      :user => Generate.user!,
      :tag => Generate.tag!
    ))
  end
  
  def self.comment!(attributes = {})
    returning self.comment(attributes) do |comment|
      comment.save!
    end
  end

  def self.user_attributes(attributes = {})
    unique_id = unique_id_for(:user)
    
    attributes.reverse_merge(
      :login => "user_#{unique_id}",
      :email => "user_#{unique_id}@example.com",
      :password => "password",
      :password_confirmation => "password",
      :firstname => "John",
      :lastname => "Doe",
      :time_zone => "UTC",
      :activated_at => Time.now
    )
  end

  def self.user(attributes = {})
    User.new(user_attributes(attributes))
  end
  
  def self.user!(attributes = {})
    returning self.user(attributes) do |user|
      user.password = nil
      user.password_confirmation = nil
      user.crypted_password = attributes[:password] ?
        BCrypt::Password.create(attributes.delete(:password)) :
        "$2a$10$UyBxy/Db9lk/jKKVsBI0dOegH6R/FY9Zx4.kuZU/7HqiMKVmLYpLG" # password
      user.save!
    end
  end
  
  def self.admin!(attributes = {})
    returning self.user!(attributes) do |admin|
      admin.has_role("admin")
    end
  end
  
  def self.tag(attributes = {})
    unique_id = unique_id_for(:tag)
    
    Tag.new(attributes.reverse_merge(
      :name => "Tag #{unique_id}",
      :user => Generate.user!
    ))
  end

  def self.tag!(attributes = {})
    returning self.tag(attributes) do |tag|
      tag.save!
    end
  end
  
  def self.tag_usage(attributes = {})
    unique_id = unique_id_for(:tag_usage)
    
    TagUsage.new(attributes.reverse_merge(
      :tag => Generate.tag!
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
      :uri => "uri:FeedItem#{unique_id}",
      :content => Generate.feed_item_content
    ))
  end
  
  def self.feed_item_content(attributes = {})
    FeedItemContent.new(attributes.reverse_merge(
      :content => "Example Content"
    ))
  end
end