# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feedbacks/_feedback.html.erb' do
  before(:each) do
    @feedback = mock_model(Feedback, :user => mock_model(User, :display_name => "John Doe"), :created_at => 3.days.ago, :body => "This is a feature requests")
    assigns[:feedback] = @feedback
    
    template.stub!(:format_date).and_return("THE DATE")
  end
  
  def render_it
    render :partial => '/feedbacks/feedback.html.erb'
  end
  
  it "displays the user who posted the feedback" do
    render_it
    response.should have_tag(".metadata", /John Doe/)
  end
  
  it "displays the date the feedback was posted" do
    template.should_receive(:format_date).with(@feedback.created_at).and_return("THE DATE")
    render_it
    response.should have_tag(".metadata", /THE DATE/)
  end
  
  it "displays the feedback message" do
    render_it
    response.should have_tag(".feedback", /This is a feature request/)    
  end
end