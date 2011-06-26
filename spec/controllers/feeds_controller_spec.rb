# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
