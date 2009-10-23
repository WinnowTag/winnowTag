# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/edit.html.erb" do  
  before do
    @message = mock_model(Message)
    @message.stub!(:body).and_return("MyText")
    @message.stub!(:pinned).and_return(true)
    assigns[:message] = @message
  end

  it "should render edit form" do
    render "/messages/edit.html.erb"
    
    response.should have_tag("form[action=#{message_path(@message)}][method=post]") do
      with_tag('textarea#message_body[name=?]', "message[body]")
      with_tag('input[type=checkbox][name=?]', 'message[pinned]')
    end
  end
end


