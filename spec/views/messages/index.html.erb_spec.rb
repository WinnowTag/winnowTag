require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/index.html.erb" do  
  before(:each) do
    message_98 = mock_model(Message)
    message_98.should_receive(:body).and_return("MyText")
    message_99 = mock_model(Message)
    message_99.should_receive(:body).and_return("MyText")

    assigns[:messages] = [message_98, message_99]
  end

  it "should render list of messages" do
    render "/messages/index.html.erb"
    response.should have_tag("tr>td", "MyText", 2)
  end
end

