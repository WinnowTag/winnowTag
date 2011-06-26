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

module CustomSeleniumHelpers
  def login(user, password = "password")
    page.open login_path
    page.type "css=#login_form input[name=login]", user.login
    page.type "css=#login_form input[name=password]", password
    page.click "commit", :wait_for => :page
  end

  def see_element(*args)
    page.is_element_present("css=#{args.join}").should be_true
  end

  def dont_see_element(*args)
    page.is_element_present("css=#{args.join}").should be_false
  end

  def assert_visible(locator)
    page.is_visible(locator).should be_true
  end
  
  def assert_not_visible(locator)
    page.is_visible(locator).should be_false
  end
  
  def hit_enter(locator)
    page.key_down(locator, '\13')
    page.key_press(locator, '\13')
    page.key_up(locator, '\13')
  end
  
  def multi_select_click(locator)
    mac? ? page.meta_key_down : page.key_down_native('17')
    page.click locator
  ensure
    mac? ? page.meta_key_up : page.key_up_native('17')
  end
  
  def mac?
    platform = page.get_eval("navigator.platform;")
    platform.include?("Mac")
  end
end