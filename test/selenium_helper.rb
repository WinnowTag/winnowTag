module SeleniumHelper
  def login(login = "quentin", password = "test")
    open login_path
    type "login", login
    type "password", password
    click "commit"
    wait_for_page_to_load
  end
  
  def refresh_and_wait
    refresh
    wait_for_page_to_load
  end
  
  def see_element(*args)
    assert is_element_present("css=#{args.join}")
  end

  def dont_see_element(*args)
    assert !is_element_present("css=#{args.join}")
  end
  
  
  
  
  

  def assert_path(path)
    url = Regexp.escape("http://") + ".+?" + Regexp.escape("/#{path}")
    url << /(\?.*)?/.inspect[1..-2]
    assert_location "regexp:^#{url}$"
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
end