# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
    
    # Maybe also support the old style
    it "should generate params { :controller => 'tags', :action => 'show', :id => 23} from GET /tags/23" do
      params_from(:get, '/tags/23').should == { :controller => 'tags', :action => 'show', :id => "23" }
    end
    
    it "should generate params { :controller => 'tags', :action => 'subscribe', :id => 23} from PUT /tags/23/subscribe" do
      params_from(:put, '/tags/23/subscribe').should == { :controller => 'tags', :action => 'subscribe', :id => "23" }
    end
  end
end
