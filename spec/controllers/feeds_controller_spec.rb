# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsController do
  describe "#index" do
    before(:each) do
      login_as Generate.user!
    end

    def do_get(params = {})
      get :index, params
    end
    
    it "is a success" do
      do_get
      response.should be_success
    end
    
    it "renders the index template" do
      do_get
      response.should render_template("index")
    end
  end
    
  describe "old specs" do
    before(:each) do
      @user = Generate.user!
      login_as @user
    end

    it "should import feeds from opml" do
      mock_feed1 = mock_model(Remote::Feed)
      mock_feed2 = mock_model(Remote::Feed)
      mock_feed1.should_receive(:collect)
      mock_feed2.should_receive(:collect)
    
      Remote::Feed.should_receive(:import_opml).
                   with(File.read(File.join(RAILS_ROOT, "spec", "fixtures", "example.opml")), @user.login).
                   and_return([mock_feed1, mock_feed2])
      post :import, :opml => fixture_file_upload("example.opml")
      response.should redirect_to(feeds_path)
      flash[:stay_notice].should == "Imported 2 feeds from your OPML file"
    end
  end
end
