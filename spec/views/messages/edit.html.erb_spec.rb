require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/edit.html.erb" do  
  before do
    @message = mock_model(Message)
    @message.stub!(:body).and_return("MyText")
    assigns[:message] = @message
  end

  it "should render edit form" do
    render "/messages/edit.html.erb"
    
    response.should have_tag("form[action=#{message_path(@message)}][method=post]") do
      with_tag('textarea#message_body[name=?]', "message[body]")
    end
  end
end


