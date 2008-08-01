# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails/story_adapter'
require 'net/http'

def run_local_story(filename, options={})
  run File.join(File.dirname(__FILE__), filename), options
end

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

def post_with_hmac(url, data, headers)
  request = Net::HTTP::Post.new(URI.parse(url).path, headers)
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  post url, data, sent_headers
end

def put_with_hmac(url, data, headers)
  request = Net::HTTP::Put.new(URI.parse(url).path, headers)
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  put url, data, sent_headers
end

def delete_with_hmac(url, params, headers)
  request = Net::HTTP::Delete.new(URI.parse(url).path, {'Content-Type' => "application/x-www-form-urlencoded"}.merge(headers))
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  delete url, params, sent_headers
end
