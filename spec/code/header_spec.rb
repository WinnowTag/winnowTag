# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "headers" do
  it "all ruby files should have the kaphan foundation header" do
    vendor = %w[lib/authenticated_system.rb lib/authenticated_test_helper.rb lib/mongrel_health_check_handler.rb lib/tasks/rspec.rake]
    
    (Dir["{app,lib,db,profiling,spec,stories}/**/*.{rb,rake}"] - vendor).each do |filename|
      filename.should have_ruby_kaphan_header
    end
  end
  
  it "all javascript files should have the kaphan foundation header" do
    vendor = %w[
      public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js
      public/javascripts/slider.js public/javascripts/unittest.js public/javascripts/all.js
    ]
    
    (Dir["public/javascripts/**/*.js"] - vendor).each do |filename|
      filename.should have_javascript_kaphan_header
    end
  end
  
  it "all stylesheets files should have the kaphan foundation header" do
    vendor = %w[public/stylesheets/all.css public/stylesheets/blueprint/screen.css]
    
    (Dir["public/stylesheets/**/*.css"] - vendor).each do |filename|
      filename.should have_stylesheet_kaphan_header
    end
  end
end
