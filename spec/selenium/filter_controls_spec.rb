require File.dirname(__FILE__) + '/../spec_helper'

describe "filter controls" do
  fixtures :users

  before(:each) do
    login
    open feed_items_path
  end
end