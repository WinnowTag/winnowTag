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