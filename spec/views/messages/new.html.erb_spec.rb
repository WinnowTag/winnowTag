# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/new.html.erb" do  
  before(:each) do
    @message = mock_model(Message)
    @message.stub!(:new_record?).and_return(true)
    @message.stub!(:body).and_return("MyText")
    assigns[:message] = @message
  end

  it "should render new form" do
    render "/messages/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", messages_path) do
      with_tag("textarea#message_body[name=?]", "message[body]")
    end
  end
end


