# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/new.html.erb" do  
  before(:each) do
    assigns[:message] = mock_model(Message, :body => "MyText", :pinned => true).as_new_record
  end

  it "should render new form" do
    render "/messages/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", messages_path) do
      with_tag("textarea#message_body[name=?]", "message[body]")
      with_tag('input[type=checkbox][name=?]', 'message[pinned]')
    end
  end
end


