# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Setting do
  before(:each) do
    @setting = Setting.new :name => "info", :value => "welcome to winnow"
  end

  it "should be valid" do
    @setting.should be_valid
  end
end
