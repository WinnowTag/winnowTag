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

describe '/messages/index.html.erb' do
  before(:each) do
    assigns[:messages] = []
    
    template.stub!(:render).with(:partial => "header_controls")
  end
  
  def render_it
    render '/messages/index.html.erb'
  end
  
  it "shows the header controls" do
    template.should_receive(:render).with(:partial => "header_controls").and_return("header controls")
    render_it
    response.capture(:header_controls).should match(/header controls/)
  end

  describe "with an empty result set" do
    it "shows an empty message" do
      render_it
      response.should have_tag(".empty")
    end
  end

  describe "with a non-empty result set" do
    before(:each) do
      @messages = [mock_model(Message), mock_model(Message)]
      assigns[:messages] = @messages
      
      template.stub!(:render).with(:partial => @messages)
    end
    
    it "does not show an empty message" do
      render_it
      response.should_not have_tag(".empty")
    end
  
    it "shows each message" do
      template.should_receive(:render).with(:partial => @messages)
      render_it
    end
  end
end
