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

Given(/^there is not a feed for "(.*)"$/) do |feed_url|
  feed = Feed.find_by_via(feed_url)
  feed.destroy if feed
end

Given /^there is a feed for "(.*)"$/ do |feed_url|
  Generate.feed! :via =>  feed_url
end

When(/^I create a feed for "(.*)"$/) do |feed_url|
  invalid_url = lambda do |url| 
    begin
      URI.parse(url)
      false
    rescue URI::InvalidURIError
      true
    end
  end
  
  non_http_url = lambda do |url|
    URI.parse(url).scheme != "http"
  end
  
  winnow_url = lambda do |url|
    URI.parse(url).host =~ /(winnow|trunk).mindloom.org/
  end
  
  ActiveResource::BetterHttpMock.define("creation") do |request, response|
    request.method  :post
    request.path    "/feeds.xml"
    request.headers "Authorization" => /^AuthHMAC winnow_id:.*/, 'Date' => /.*/, 'Content-Type' => "application/xml"
    request.body    Remote::Feed.new(:url => feed_url, :created_by => current_user.login).to_xml
    response['Content-Type'] = "application/xml"

    if invalid_url.call(feed_url)
      response.code    422
      response.body    %Q|
        <?xml version="1.0" encoding="UTF-8"?>
        <errors>
          <error>Url is invalid</error>
        </errors>
      |
    elsif non_http_url.call(feed_url)
      response.code    422
      response.body    %Q|
        <?xml version="1.0" encoding="UTF-8"?>
        <errors>
          <error>Url is not http</error>
        </errors>
      |
    elsif winnow_url.call(feed_url)
      response.code    422
      response.body    %Q|
        <?xml version="1.0" encoding="UTF-8"?>
        <errors>
          <error>Winnow generated feeds cannot be added to Winnow</error>
        </errors>
      |
    else
      feed = Feed.find_by_via(feed_url)
      response.code    201
      response.headers 'Location' => '/feeds/23'
      response.body    Remote::Feed.new(:url => feed_url, :created_by => current_user.login, :uri => feed ? feed.uri : "NewFeed").to_xml
    end
  end                
                     
  ActiveResource::BetterHttpMock.define("collection") do |request, response|
    request.method  :post
    request.path    "/feeds/23/collection_jobs.xml"
    request.headers "Authorization" => /^AuthHMAC winnow_id:.*/, 'Date' => /.*/, 'Content-Type' => "application/xml"
    request.body    Remote::CollectionJob.new(:callback_url => "http://www.example.com/users/#{current_user.login}/collection_job_results", :created_by => current_user.login).to_xml

    # TODO: Is this response right?
    response.code    201
    response.headers 'Location' => '/collection_jobs/23'
    response.body    Remote::CollectionJob.new(:callback_url => "http://www.example.com/users/#{current_user.login}/collection_job_results", :created_by => current_user.login).to_xml
  end

  visit feeds_path
  fill_in "feed_url", :with => feed_url
  click_button "Add Feed"
end

# TODO: Make these smarter
Then(/^I see the notice "(.*)"$/) do |notice|
  response.body.should include_text(notice)
end

Then /^I see the error "(.*)"$/ do |error|
  response.body.should include_text(error)
end

Then(/^I see the feed for "(.*)"$/) do |feed_url|
  visit feeds_path(:format => "json")
  response.body.should include_text(feed_url)
end

Then(/^I am subscribed to "(.*)"$/) do |feed_url|
  feed = Feed.find_by_via!(feed_url)
  visit sidebar_feed_items_path
  response.body.should include_text("feed_#{feed.id}")
end

Then(/^"(.*)" is created on the collector$/) do |feed_url|
  ActiveResource::BetterHttpMock.should have_executed("creation")
end

Then(/^"(.*)" is scheduled for collection$/) do |feed_url|
  ActiveResource::BetterHttpMock.should have_executed("collection")
end

Then /^I see the add feeds form$/ do
  response.body.should have_tag("form[action=?][method=post]", feeds_path)
end

Then /^I see the url is set to "(.*)"$/ do |feed_url|
  response.body.should have_tag("input#feed_url[value=?]", feed_url)
end
