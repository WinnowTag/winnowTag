# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TagUsage do
  describe "validations" do
    it "validates presence of tag id" do
      tag = Generate.tag_usage(:tag => nil)
      tag.should have(1).error_on(:tag)
    end
  end
end
