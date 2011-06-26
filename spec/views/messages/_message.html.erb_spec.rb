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

require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/_message.html.erb" do    
  before(:each) do
    @time = Time.now
    @message = mock_model(Message, :body => "foo", :created_at => @time)

    template.stub!(:format_date).and_return("the date")
  end

  def render_it
    render :partial => "/messages/message", :locals => { :message => @message }
  end
  
  it "displays the message body" do
    render_it
    response.should have_tag(".message .body", "foo")
  end
  
  it "displays the message created time" do
    template.should_receive(:format_date).with(@time).and_return("the date")
    render_it
    response.should have_tag(".message .date", "the date")
  end
  
  it "displays the edit link" do
    render_it
    response.should have_tag(".controls a[class=edit][href=?]", edit_message_path(@message))
  end
  
  it "displays the destroy link" do
    render_it
    response.should have_tag(".controls a[class=destroy][href=?]", message_path(@message))
  end
end
