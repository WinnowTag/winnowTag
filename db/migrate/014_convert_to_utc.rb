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

class ConvertToUtc < ActiveRecord::Migration
  class Classifier < ActiveRecord::Base;  end
  class Tagging < ActiveRecord::Base;  end
  class RolesUsers < ActiveRecord::Base
    table_name = 'roles_users'
    cattr_accessor :combined_pk
    @combined_pk = [:user_id, :role_id]
  end
  
  def self.up
    ActiveRecord::Base.default_timezone = :local
    ActiveRecord::Base.transaction do
      say_with_time "Converting Classifiers to UTC..." do
        Classifier.find(:all).each do |c|
          convert_time(c, :utc, :created_on, :updated_on, :deleted_at, :last_executed)
        end
      end
    
      say_with_time "Converting FeedItems to UTC..." do
        FeedItem.find(:all).each do |fi|
          convert_time(fi, :utc, :time, :time_retrieved)
        end
      end
    
      say_with_time "Converting Feeds to UTC..." do
        Feed.find(:all).each do |f|
          convert_time(f, :utc, :time_last_retrieved)
        end
      end
    
      say_with_time "Converting Roles to UTC..." do
        Role.find(:all).each do |r|
          convert_time(r, :utc, :created_at, :updated_at)
        end
      end
    
      say_with_time "Converting RolesUsers to UTC..." do
        RolesUsers.find(:all).each do |ru|
          convert_time(ru, :utc, :created_at, :updated_at)
        end
      end
    
      say_with_time "Converting Users to UTC..." do
        User.find(:all).each do |u|
          convert_time(u, :utc, :created_at, :updated_at, :logged_in_at, :deleted_at, :activated_at, :remember_token_expires_at)
        end
      end
      
      say_with_time "Converting Taggings to UTC..." do
        Tagging.find(:all).each do |t|
          convert_time(t, :utc, :created_on, :deleted_at)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.default_timezone = :utc
    ActiveRecord::Base.transaction do
      say_with_time "Reverting Classifiers to Local time..." do
        Classifier.find_with_deleted(:all).each do |c|
          convert_time(c, :local, :created_on, :updated_on, :deleted_at, :last_executed)
        end
      end
    
      say_with_time "Revering FeedItems to Local time..." do
        FeedItem.find(:all).each do |fi|
          convert_time(fi, :local, :time, :time_retrieved)
        end
      end
    
      say_with_time "Reverting Feeds to Local time..." do
        Feed.find(:all).each do |f|
          convert_time(f, :local, :time_last_retrieved)
        end
      end
    
      say_with_time "Reverting Roles to Local time..." do
        Role.find(:all).each do |r|
          convert_time(r, :local, :created_at, :updated_at)
        end
      end
    
      say_with_time "Converting RolesUsers to Local time..." do
        RolesUsers.find(:all).each do |ru|
          convert_time(ru, :local, :created_at, :updated_at)
        end
      end
      
      say_with_time "Converting Users to Local time..." do
        User.find(:all).each do |u|
          convert_time(u, :local, :created_at, :updated_at, :logged_in_at, :deleted_at, :activated_at, :remember_token_expires_at)
        end
      end
    
      say_with_time "Converting Taggings to Local time..." do
        Tagging.find_with_deleted(:all).each do |t|
          convert_time(t, :local, :created_on, :deleted_at)
        end
      end
    end
  end
  
  # Need to do the conversion using SQL since we dont want timestamps to actually be updated, just shifted by timezone.
  def self.convert_time(obj, timezone, *time_columns)
    connection = ActiveRecord::Base.connection
    
    # collect times in new timezone
    new_times = {}
    time_columns.each do |time_column|
      new_times[time_column] = (obj.send(time_column) and obj.send(time_column).send('get' + timezone.to_s))
    end
  
    # build and execute the update SQL
    sql = "UPDATE #{obj.class.table_name} SET "
    sql << time_columns.map do |time_column|
      if new_times[time_column]
        "#{time_column.to_s} = #{connection.quote(new_times[time_column])}"
      end
    end.compact.join(', ')
    
    if obj.id
      sql << " where #{obj.class.primary_key} = #{connection.quote(obj.id)}"
    elsif obj.combined_pk
      sql << " where "
      obj.combined_pk.map do |pk|
        "pk.to_s = #{connection.quote(obj.send(pk))}"
      end.join(' and ')
    end
    
    suppress_messages { execute sql }
  end
end
