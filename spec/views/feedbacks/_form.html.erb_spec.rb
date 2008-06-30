# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feedbacks/_form.html.erb' do
  before(:each) do
    @feedback = mock_new_model(Feedback, :body => nil)
  end
  
  def render_it
    render :partial => '/feedbacks/form.html.erb', :locals => { :feedback => @feedback }
  end
  
  it "displasy the from" do
    render_it
    response.should have_tag("form[method=post][action=?]", feedbacks_path) do
      with_tag("textarea[name=?]", "feedback[body]")
      with_tag("input[type=submit]")
      with_tag("a[onclick*=?]", "remove")
    end
  end
end