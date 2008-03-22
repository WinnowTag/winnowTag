require File.dirname(__FILE__) + '/../spec_helper'

describe Folder do
  it "does not allow 2 folders to be named the same for same user" do
    Folder.create! :name => "demo", :user_id => 1
    folder = Folder.new :name => "demo", :user_id => 1
    folder.should_not be_valid
    folder.should have(1).errors_on(:name)
  end
  
  it "allows 2 folders to be named the same for different users" do
    Folder.create! :name => "demo", :user_id => 1
    folder = Folder.new :name => "demo", :user_id => 2
    folder.should be_valid
  end
  
  it "allows 2 folders to be named differently for the same user" do
    Folder.create! :name => "demo", :user_id => 1
    folder = Folder.new :name => "demo2", :user_id => 1
    folder.should be_valid
  end
end