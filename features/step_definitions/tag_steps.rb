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

Given("a public tag in the system") do
  @user = Generate.user!
  @tag = Generate.tag!(:user => @user, :public => true)
end

When("I access /username/tags/tagname.atom") do
  get "/#{@tag.user.login}/tags/#{@tag.name}.atom"
end

When("I access /tags.atom") do
  get_with_hmac "/tags.atom"
end

When("I access that tag's tagging information") do
  get information_tag_path(@tag)
end

Then("the response is $code") do |code|
  response.code.should == code
end

Then("the content type is atom") do
  response.content_type.should == "application/atom+xml"
end

Then("the body is parseable by ratom") do
  lambda { Atom::Feed.load_feed(response.body) }.should_not raise_error
end