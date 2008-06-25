# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe Setting do
  before(:each) do
    @setting = Setting.new
  end

  it "should be valid" do
    @setting.should be_valid
  end
end
