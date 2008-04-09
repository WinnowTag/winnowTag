require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/show.html.erb" do  
  before(:each) do
    @message = mock_model(Message)
    @message.stub!(:body).and_return("MyText")

    assigns[:message] = @message
  end

  it "should render attributes in <p>" do
    render "/messages/show.html.erb"
    response.should have_text(/MyText/)
  end
end

