# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe TagsHelper do
  describe "#cancel_link" do
    before(:each) do
      @tag = mock_model(Tag)
    end

    it "returns a link to the tags path when on a normal request" do
      cancel_link(@tag).should == link_to("Cancel", tags_path)
    end
    
    it "returns a link to hide a form when on an ajax request" do
      request.stub!(:xhr?).and_return(true)
      cancel_link(@tag).should == link_to_function("Cancel", visual_effect(:blind_up, dom_id(@tag, 'form'), :duration => 0.3))
    end
  end
end