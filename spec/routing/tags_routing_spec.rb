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

describe TagsController do
  describe "route generation" do
    it "should map { :controller => 'tags', :action => 'index'} to /tags" do
      route_for(:controller => 'tags', :action => 'index').should == '/tags'
    end
    
    it "should map { :controller => 'tags', :action => 'index', :user => 'bob'} to /bob/tags" do
      route_for(:controller => 'tags', :action => 'index', :user => 'bob').should == '/bob/tags'
    end
    
    it "should map { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag'} to /bob/tags/mytag" do
      route_for(:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag').should == '/bob/tags/mytag'
    end    
    
    it "should map { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag'} to /bob/tags/mytag/training" do 
      route_for(:controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag').should == '/bob/tags/mytag/training'
    end
    
    it "should map { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag'} to /bob/tags/mytag/classifier_taggings" do
      route_for(:controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag').should == '/bob/tags/mytag/classifier_taggings'
    end
    
    it "should map { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} to /bob/tags/mytag.atom" do
      route_for(:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag', :format => 'atom').should == '/bob/tags/mytag.atom'
    end
    
    it "should map { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} to /bob/tags/mytag/training.atom" do
      route_for(:controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag', :format => 'atom').should == '/bob/tags/mytag/training.atom'
    end
    
    it "should map { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} to /bob/tags/mytag/classifier_taggings.atom" do
      route_for(:controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag', :format => 'atom').should == '/bob/tags/mytag/classifier_taggings.atom'
    end
    
    # some funky tags
    it "should map {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag'} to /bob/tags/my%20tag" do
      route_for({:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag'}).should == '/bob/tags/my%20tag'
    end
    
    it "should map {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag?'} to /bob/tags/my%20tag%3F" do
      route_for({:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag?'}).should == '/bob/tags/my%20tag%3F'
    end
          
    # Maybe also support the old style
    it "should map { :controller => 'tags', :action => 'show', :id => 23} to /tags/23" do
      route_for(:controller => 'tags', :action => 'show', :id => "23").should == '/tags/23'
    end
    
    it "should map { :controller => 'tags', :action => 'subscribe', :id => 23} to /tags/23/subscribe" do
      route_for(:controller => 'tags', :action => 'subscribe', :id => "23").should == { :path => '/tags/23/subscribe', :method => :put }
    end
  end
  
  describe "route recognition" do
    it "should generate params { :controller => 'tags', :action => 'index', :user => 'bob'} from GET /bob/tags" do
      params_from(:get, '/bob/tags').should == { :controller => 'tags', :action => 'index', :user => 'bob' }
    end
    
    it "should generate params { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag'} from GET /bob/tags/mytag" do
      params_from(:get, '/bob/tags/mytag').should == { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag' }
    end
    
    it "should generate params { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag'} from GET /bob/tags/mytag/training" do
      params_from(:get, '/bob/tags/mytag/training').should == { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag'}
    end
    
    it "should generate params { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag'} from GET /bob/tags/mytag/classifier_taggings" do
      params_from(:get, '/bob/tags/mytag/classifier_taggings').should == { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag'}
    end
    
    it "should generate params { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} from GET /bob/tags/mytag.atom" do
      params_from(:get, '/bob/tags/mytag.atom').should == { :controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'mytag', :format => 'atom' }
    end
    
    it "should generate params { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} from GET /bob/tags/mytag/training.atom" do
      params_from(:get, '/bob/tags/mytag/training.atom').should == { :controller => 'tags', :action => 'training', :user => 'bob', :tag_name => 'mytag', :format => 'atom'}
    end
    
    it "should generate params { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag', :format => 'atom'} from GET /bob/tags/mytag/classifier_taggings.atom" do
      params_from(:get, '/bob/tags/mytag/classifier_taggings.atom').should == { :controller => 'tags', :action => 'classifier_taggings', :user => 'bob', :tag_name => 'mytag', :format => 'atom'}
    end
    
    # some funky tags
    it "should map {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag'} to /bob/tags/my%20tag" do
      params_from(:get, '/bob/tags/my%20tag').should == {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag'}
    end
    
    it "should map {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag?'} to /bob/tags/my%20tag%3F" do
      params_from(:get, '/bob/tags/my%20tag%3F').should == {:controller => 'tags', :action => 'show', :user => 'bob', :tag_name => 'my tag?'}
    end
    
    # Maybe also support the old style
    it "should generate params { :controller => 'tags', :action => 'show', :id => 23} from GET /tags/23" do
      params_from(:get, '/tags/23').should == { :controller => 'tags', :action => 'show', :id => "23" }
    end
    
    it "should generate params { :controller => 'tags', :action => 'subscribe', :id => 23} from PUT /tags/23/subscribe" do
      params_from(:put, '/tags/23/subscribe').should == { :controller => 'tags', :action => 'subscribe', :id => "23" }
    end
  end
end
