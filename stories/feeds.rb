# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

require File.dirname(__FILE__) + '/helper'
require 'active_resource/http_mock'

steps_for(:feeds) do
  Given("I am logged in") do
    User.delete_all
    User.create!(valid_user_attributes(:login => 'quentin')).should_not be_nil
    post '/account/login', :login => 'quentin', :password => 'password'
    response.code.should == "302"
  end
  
  Given('no feeds in the system') do
    Feed.delete_all 
  end
  
  Given('a running collector') do
    ActiveResource::HttpMock.respond_to do |http|
      http.post  "/feeds.xml", {}, {:url => 'http://example.org/feed', :created_by => 'quentin'}.to_xml(:root => 'feed'), 201, 'Location' => '/feeds/23'
      http.post  "/feeds/23/collection_jobs.xml", {}, 
                 {:callback_url => 'http://www.example.com/users/quentin/collection_job_results', :created_by => 'quentin'}.to_xml(:root => 'collection_job'), 201, 'Location' => '/feeds/23'
    end
  end
  
  When("I create a new feed from $url") do |url|
    post '/feeds', :feed => { :url => url }
  end
  
  Then("I am redirected") do
    response.code.should == "302"
  end
end

with_steps_for(:feeds) do
  run_local_story 'feeds', :type => RailsStory
end