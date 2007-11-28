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
  click "commit"
  wait_for_page_to_load 30000
end