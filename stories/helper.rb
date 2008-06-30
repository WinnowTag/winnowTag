# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails/story_adapter'

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
    :lastname => "Doe_#{unique_id}"
  }.merge(attributes)
end
