# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsPresenter do
  it "can find a list of feeds" do
    @user = stub("user")
    @feeds = stub("feeds")
    Feed.should_receive(:search).with(:search_term => "Ruby", :excluder => @user, :page => "2", :order => "title ASC").and_return(@feeds)

    presenter = FeedsPresenter.new :current_user => @user, :search_term => "Ruby", :page => "2", :order => "title ASC"
    presenter.feeds.should == @feeds
  end
end