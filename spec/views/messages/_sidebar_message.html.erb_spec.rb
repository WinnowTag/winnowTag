require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/_sidebar_message.html.erb" do    
  before(:each) do
    @time = Time.now
    @message = mock_model(Message, :body => "foo", :created_at => @time)

    template.stub!(:format_date).and_return("the date")
  end

  def render_it
    render :partial => "/messages/sidebar_message", :locals => { :sidebar_message => @message }
  end
  
  it "displays the message body" do
    render_it
    response.should have_tag(".body", "foo")
  end
  
  it "displays the message created time" do
    template.should_receive(:format_date).with(@time).and_return("the date")
    render_it
    response.should have_tag(".date", "the date")
  end
end