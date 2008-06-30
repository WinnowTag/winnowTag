# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/users/index.csv.erb' do
  def render_it
    render "/users/index.csv.erb"
  end
  
  it "exports csv with login, name, email, and last logged in date" do
    time, time2 = Time.now, 2.days.ago
    assigns[:users] = [
      mock_model(User, :login => "john", :display_name => "John Hwang", :email => "john@example.com", :logged_in_at => time),
      mock_model(User, :login => "mark", :display_name => "Mark Van", :email => "mark@example.com", :logged_in_at => time2)]
    
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