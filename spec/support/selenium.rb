# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
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
    mac? ? page.meta_key_down : page.control_key_down
    page.click locator
    mac? ? page.meta_key_up : page.control_key_up
  end
  
  def mac?
    platform = page.get_eval("navigator.platform;")
    platform.include?("Mac")
  end
end