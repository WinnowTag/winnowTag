ActionController::Routing::Routes.draw do |map|
  map.namespace :item_cache do |item_cache|
    item_cache.resources :feed_items, :requirements => {:id => %r{[^/;,?]+}}
    item_cache.resources :feeds, :requirements => {:id => %r{[^/;,?]+}} do |feeds|
      feeds.resources :feed_items,:requirements => {:feed_id => %r{[^/;,?]+}, :id => %r{[^/;,?]+}}
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
                  :clues => :get,
                  :moderation_panel => :get,
                  :feed_information => :get,
                  :body => :get,
                  :mark_read => :put,
                  :mark_unread => :put
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
                  :update_state => :put,
                  :globally_exclude => :post,
                  :publicize => :put, 
                  :subscribe => :put,
                  :unsubscribe => :put, 
                  :sidebar => :put,
                  :auto_complete_for_tag_name => :any,
                  :training => :get,
                  :information => :get,
                  :classifier_taggings => [:post, :put],
                  :merge => :put,
                  :comments => :get
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
  
  map.resources :folders, 
                :member => {
                  :add_item => :put,
                  :remove_item => :put
                },
                :collection => {
                  :sort => :put
                }
              
  map.resources :messages  
  map.resources :feedbacks
  map.resources :comments
                
  map.with_options :controller => "account" do |account_map|
    account_map.edit_account "account/edit/:id", :action => "edit"
    account_map.login "account/login/:code", :action => "login", :code => nil
    account_map.signup "account/signup", :action => "signup", :conditions => { :method => :post }
    account_map.signup_invite "account/invite", :action => "invite", :conditions => { :method => :post }
    account_map.logout "account/logout", :action => "logout"
    account_map.activate "account/activate", :action => "activate"
    account_map.reminder "account/reminder", :action => "reminder", :conditions => { :method => :post }
  end
  
  map.with_options :controller => "about" do |about_map|
    about_map.about "about"
    about_map.info "info", :action => "info"
  end
  
  map.with_options :controller => "admin" do |admin_map|
    admin_map.admin "admin"
    admin_map.admin_info "admin/info", :action => "info"
    admin_map.admin_help "admin/help", :action => "help"
  end
  
  map.root :controller => "feed_items"
end
