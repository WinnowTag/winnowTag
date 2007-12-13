# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  
  def valid_feed_item_attributes(attributes = {})
    unique_id = rand(10000)
    { :link => "http://#{unique_id}.example.com", 
      :unique_id => unique_id
    }.merge(attributes)
  end
  
  def valid_feed_attributes(attributes = {})
    unique_id = rand(1000)
    { :url => "http://#{unique_id}.example.com/index.xml",
      :link => "http://#{unique_id}.example.com",
      :title => "#{unique_id} Example",
      :feed_items_count => 0,
      :updated_on => Time.now
    }.merge(attributes)
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
  
  def login_as(user_id)
    session[:user] = user_id
  end
  
  def mock_user_for_controller
    @user = mock_model(User, valid_user_attributes)
    @tags = mock("tags")
    @views = mock("views")
    
    @view = mock_model(View)
    @view.stub!(:set_as_default!)
    @views.stub!(:find).and_return(@view)
    @views.stub!(:default).and_return(@view)
    
    User.stub!(:find_by_id).and_return(@user)
    @user.stub!(:tags).and_return(@tags)
    @user.stub!(:views).and_return(@views)
  end
  
  def mock_model_with_dom_id(cls, attributes)
    m = mock_model(cls, attributes)    
    m.stub!(:dom_id).with(no_args()).and_return("#{cls.name.underscore}_#{m.id}")
    m.should_receive(:dom_id).with(an_instance_of(String)).any_number_of_times.and_return {|p| "#{p}_#{cls.name.underscore}_#{m.id}"}
    m
  end
end
