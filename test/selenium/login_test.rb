require File.dirname(__FILE__) + '/../test_helper'

class LoginTest < Test::Unit::SeleniumTestCase
  def test_truth
    open "/account/login"
    type "login", "quentin"
    type "password", "test"
    click "commit"
    wait_for_page_to_load
    assert_match feed_items_url, get_location
  end
end

# assert(@selenium.get_text("link").index("Click here for next page") != nil, "link 'link' doesn't contain expected text")
# links = @selenium.get_all_links()
# assert(links.length > 3)
# assert_equal("linkToAnchorOnThisPage", links[3])
# @selenium.click("link")
# @selenium.wait_for_page_to_load(5000)
# assert(@selenium.get_location =~ %r"/selenium-server/tests/html/test_click_page2.html")
# @selenium.click("previousPage")
# @selenium.wait_for_page_to_load(5000)
# assert(@selenium.get_location =~ %r"/selenium-server/tests/html/test_click_page1.html")
