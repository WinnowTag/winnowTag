# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe  TagSubscription do
  describe "associations" do
    
    before(:each) do
      @tag_subscription = TagSubscription.new
    end
    
    it "belong to user" do
      @tag_subscription.should belong_to(:user)
    end
    
    it "belongs to tag" do
      @tag_subscription.should belong_to(:tag)      
    end
  end
end
