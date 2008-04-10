require File.dirname(__FILE__) + '/../../spec_helper'

describe "/messages/_message.html.erb" do    
  before(:each) do
    @time = Time.now
    @message = mock_model(Message, :body => "foo", :created_at => @time)

    template.stub!(:format_date).and_return("the date")
  end

  def render_it
    render :partial => "/messages/message", :locals => { :message => @message }
  end
  
  it "displays the message body" do
    render_it
    response.should have_tag(".message .body", "foo")
  end
  
  it "displays the message created time" do
    template.should_receive(:format_date).with(@time).and_return("the date")
    render_it
    response.should have_tag(".message .date", "the date")
  end
  
  it "displays the edit link" do
    render_it
    response.should have_tag(".controls a[class=edit_icon][href=?]", edit_message_path(@message))
  end
  
  it "displays the destroy link" do
    render_it
    response.should have_tag(".controls a[class=destroy_icon][href=?]", message_path(@message))
  end
end