# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe "kaphan foundation header" do
  it "should be required on all ruby files" do
    vendor = %w[
      lib/authenticated_system.rb lib/authenticated_test_helper.rb
      lib/mongrel_health_check_handler.rb 
      lib/tasks/cucumber.rake lib/tasks/rspec.rake
      features/support/env.rb features/step_definitions/webrat_steps.rb
      db/schema.rb
    ]
    
    (Dir["{app,lib,db,profiling,spec,features}/**/*.{rb,rake}"] - vendor).each do |filename|
      filename.should have_ruby_kaphan_header
    end
  end
  
  it "should be required on all javascript files" do
    vendor = %w[
      public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js
      public/javascripts/slider.js public/javascripts/unittest.js public/javascripts/all.js public/javascripts/locales.js
      public/javascripts/placeholder.js
    ]
    
    (Dir["public/javascripts/**/*.js"] - vendor).each do |filename|
      filename.should have_javascript_kaphan_header
    end
  end
  
  it "should be required on all stylesheet files" do
    vendor = %w[
      public/stylesheets/all.css
      public/stylesheets/button.css public/stylesheets/defaults.css
    ]
    
    (Dir["public/stylesheets/**/*.css"] - vendor).each do |filename|
      filename.should have_stylesheet_kaphan_header
    end
  end
end
