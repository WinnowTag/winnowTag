ActionController::Routing::Routes.draw do |map|
  map.namespace :item_cache do |item_cache|
    item_cache.resources :feed_items
    item_cache.resources :feeds do |feeds|
      feeds.resources :feed_items
    end
  end
  
  map.resources :invites, 
                :member => {
                  :activate => :put
                }
  map.resources :users,
                :member => { 
                  :login_as => :post
                }
                
  map.resources :feeds,
                :member => {
                  :globally_exclude => :post,
                  :subscribe => :put,
                  :unsubscribe => :put
                },
                :collection => {
                  :auto_complete_for_feed_title => :any,
                  :import => :any
                }
  map.resources :feed_items,
                :member => {
                  :inspect => :get,
                  :mark_read => :put,
                  :mark_unread => :put,
                  :info => :get,
                  :description => :get,
                  :moderation_panel => :get
                },
                :collection => { 
                  :mark_read => :put,
                  :sidebar => :get
                }                
                
  map.with_options :controller => "tags" do |tags_map|
    tags_map.connect ":user/tags.:format", :action => 'index'
    tags_map.connect ":user/tags", :action => 'index'
    tags_map.with_options :requirements => {:tag_name => %r{[^/;,?]+}} do |tags_map|
      tags_map.connect ":user/tags/:tag_name.:format", :action => 'show'
      tags_map.connect ":user/tags/:tag_name", :action => 'show'
      tags_map.connect ":user/tags/:tag_name/:action.:format"
      tags_map.connect ":user/tags/:tag_name/:action"
    end
  end
  
  map.resources :tags,
                :collection => { 
                  :public => :get,
                  :auto_complete_for_tag_name => :any,
                  :auto_complete_for_sidebar => :any
                },
                :member => { 
                  :globally_exclude => :post,
                  :publicize => :put, 
                  :subscribe => :put,
                  :unsubscribe => :put, 
                  :sidebar => :put,
                  :auto_complete_for_tag_name => :any,
                  :training => :get,
                  :classifier_taggings => :any,
                  :merge => :put
                }
  
  map.public_tag "tags/public/:user_id/:id", :controller => "tags", :action => "show"
  map.formatted_public_tag "tags/public/:user_id/:id.:format", :controller => "tags", :action => "show"
  
  map.with_options :controller => "taggings" do |taggings_map|
    taggings_map.connect 'taggings/create', :action => "create"
    taggings_map.connect 'taggings/destroy', :action => "destroy"
  end
  
  map.resource :classifier, :controller => "classifier",
               :member => {
                 :status => :post,
                 :cancel => :post,
                 :classify => :post
               }
              
  map.resources :collection_job_results, :path_prefix => '/users/:user_id'
  map.resource :item_protection, :controller => "item_protection",
                :member => {
                  :rebuild => :post
                }

  map.resources :folders, 
                :member => {
                  :add_item => :put,
                  :remove_item => :put
                }
              
  map.resources :messages
                
  map.with_options :controller => "account" do |account_map|
    account_map.edit_account "account/edit", :action => "edit"
    account_map.login "account/login/:code", :action => "login", :code => nil
    account_map.signup "account/signup", :action => "signup", :conditions => { :method => :post }
    account_map.signup_invite "account/invite", :action => "invite", :conditions => { :method => :post }
    account_map.logout "account/logout", :action => "logout"
    account_map.activate "account/activate", :action => "activate"
    account_map.reminder "account/reminder", :action => "reminder", :conditions => { :method => :post }
  end
  
  map.with_options :controller => "about" do |about_map|
    about_map.about "about"
    about_map.using "using", :action => "using"
  end
  
  map.with_options :controller => "admin" do |admin_map|
    admin_map.admin "admin"
    admin_map.admin_using "admin/using", :action => "using"
    admin_map.admin_help "admin/help", :action => "help"
  end
  
  map.root :controller => "feed_items"
end
