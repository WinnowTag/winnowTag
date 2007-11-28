# It's often a good idea to start the test with 'setup'.
# See /selenium/setup for more info.

# More information about the commands is available at:
#   http://release.openqa.org/selenium-core/nightly/reference.html
# See also the RDoc for SeleniumOnRails::TestBuilder.

# Point the browser to http://localhost:3000/selenium/tests/login.rsel to see
# how this test is rendered, or to http://localhost:3000/selenium to
# run the suite.

def login(login = "quentin", password = "test")
  open "/account/login"
  type "login", login
  type "password", password
  click_and_wait "commit"
end

def assert_path(path)
  url = Regexp.escape("http://") + ".+?" + Regexp.escape("/#{path}")
  url << /(\?.*)?/.inspect[1..-2]
  assert_location "regexp:^#{url}$"
end

def see_element(*args)
  assert_element_present "css=#{args.join}"
end

def dont_see_element(*args)
  assert_element_not_present "css=#{args.join}"
end

def assert_element_disabled(selector)
  see_element("#{selector}[disabled]")
end

def assert_element_enabled(selector)
  dont_see_element("#{selector}[disabled]")
end

def valid_user_attributes(attributes = {})
  unique_id = rand(1000)
  { :login => "user_#{unique_id}",
    :email => "user_#{unique_id}@example.com",
    :password => "password",
    :password_confirmation => "password",
    :firstname => "John_#{unique_id}",
    :lastname => "Doe_#{unique_id}"
  }.merge(attributes)
end

def valid_tag_attributes(attributes = {})
  unique_id = rand(1000)
  {
    :name => "Tag #{unique_id}",
    :user_id => unique_id
  }.merge(attributes)
end
