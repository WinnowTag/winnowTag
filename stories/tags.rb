# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/helper'

steps_for(:tags) do
  Given("a public tag in the system") do
    @user = User.create!(valid_user_attributes)
    @tag = Tag.create!(:name => 'storytag', :user => @user, :public => true)
  end
  
  When("I access /username/tags/tagname.atom") do
    get "/#{@tag.user.login}/tags/#{@tag.name}.atom"
  end
  
  When("I access /tags.atom") do
    get "/tags.atom"
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
end

with_steps_for(:tags) do
  run_local_story 'tags', :type => RailsStory
end