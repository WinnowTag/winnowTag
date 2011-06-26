# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
      public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js public/javascripts/prototype_1.7.js
      public/javascripts/slider.js public/javascripts/unittest.js public/javascripts/all.js public/javascripts/locales.js
      public/javascripts/placeholder.js public/javascripts/google_analytics_proxy.js
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
