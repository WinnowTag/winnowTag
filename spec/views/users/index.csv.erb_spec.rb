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

describe '/users/index.csv.erb' do
  def render_it
    render "/users/index.csv.erb"
  end
  
  it "exports csv with login, name, email, and last logged in date" do
    time, time2 = Time.now, 2.days.ago
    assigns[:users] = [
      mock_model(User, :login => "john", :full_name => "John Hwang", :email => "john@example.com", :logged_in_at => time),
      mock_model(User, :login => "mark", :full_name => "Mark Van", :email => "mark@example.com", :logged_in_at => time2)]
    
    template.should_receive(:format_date).with(time).and_return("the date")
    template.should_receive(:format_date).with(time2).and_return("the other date")
    
    render_it
    response.body.should == <<-EOCSV
Login,Name,Email,Last Logged In
john,John Hwang,john@example.com,the date
mark,Mark Van,mark@example.com,the other date
    EOCSV
  end
end