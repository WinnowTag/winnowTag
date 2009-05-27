# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
Given(/^I am logged in$/) do
  @current_user = Generate.user!
  post login_path, :login => @current_user.login, :password => "password"
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