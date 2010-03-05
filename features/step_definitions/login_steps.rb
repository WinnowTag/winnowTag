# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
Given(/^I am logged in$/) do
  @current_user = Generate.user!
  post login_path, :login => @current_user.login, :password => "password"
end

Given "There is a demo user" do
  Generate.user!(:login => "pw_demo")
end

When "I log in" do
  @current_user = Generate.user!
  request_page(login_path, :post, :login => @current_user.login, :password => "password")
end

When "I log out" do
  get logout_path
  puts response.location
end

When "I log in with the wrong password" do
  @current_user = Generate.user!
  request_page(login_path, :post, :login => @current_user.login, :password => "wrongpassword")
end

When "I visit $path" do |path|
  visit path
end

Then /^I am redirected via rjs to (.*)$/ do |page_name|
  response.body.should =~ /window\.location\.href = "#{Regexp.escape(path_to(page_name))}";/
end

Then /^I am redirected to (.*)$/ do |page_name|
  Then "I should be on #{page_name}"
end