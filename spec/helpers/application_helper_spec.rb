require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper, "referrer with new view" do
  
  it "generates a url based on the HTTP referrer with a new view id" do
    request.env['HTTP_REFERER'] = "http://example.com/tags?view_id=12"
    
    mock_view = mock_model(View)
    referrer_with_new_view(mock_view).should == "http://example.com/tags?view_id=#{mock_view.id}"
  end
  
  it "generates a url based on the HTTP referrer with a new view" do
    request.env['HTTP_REFERER'] = "http://example.com/tags?view_id=12"
    
    referrer_with_new_view(:new).should == "http://example.com/tags?view_id=new"
  end
end
