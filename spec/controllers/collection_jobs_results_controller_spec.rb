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

describe CollectionJobResultsController do
  before(:each) do
    @message = mock_model(Message)
    @messages = stub("messages", :create! => @message)

    @user = mock_model(User)
    @user.stub!(:messages).and_return(@messages)
    User.stub!(:find).and_return(@user)
    
    @feed = mock_model(Feed, :title => "Some Blog", :duplicate => nil)
    Feed.stub!(:find_by_id).with(@feed.id.to_s).and_return(@feed)
    
    @controller.stub!(:hmac_authenticated?).and_return(true)
  end
  
  def do_post(message = nil)
    post :create, :collection_job_result => { :message => message, :failed => !message.nil?, :feed_id => @feed.id.to_s }, :user_id => @user.id
  end

  it "is created" do
    do_post
    response.code.should == "201"
  end
  
  it "creates a failure messsage when unsuccessful" do
    @messages.should_receive(:create!).with(:body => I18n.t("winnow.notifications.collection_failed", :title => "Some Blog", :message => "Couldn't contact server")).and_return(@message)  
    do_post("Couldn't contact server")
  end
  
  it "reponds with 401 if hmac is not authenticated" do
    @controller.should_receive(:hmac_authenticated?).and_return(false)
    do_post
    response.code.should == "401"
  end
end