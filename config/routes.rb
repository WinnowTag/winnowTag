ActionController::Routing::Routes.draw do |map|
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
                  :all => :get,
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
                  :mark_read => :put
                }

  map.resources :tags,
                :collection => { 
                  :public => :get,
                  :auto_complete_for_tag_name => :any
                },
                :member => { 
                  :publicize => :put, 
                  :subscribe => :put,
                  :unsubscribe => :put, 
                  :auto_complete_for_tag_name => :any
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
                
  map.resources :views, 
                :member => { 
                  :add_feed => :post, 
                  :remove_feed => :post, 
                  :add_tag => :post, 
                  :remove_tag => :post, 
                  :duplicate => :post
                }
  
  map.with_options :controller => "account" do |account_map|
    account_map.edit_account "account/edit", :action => "edit"
    account_map.login "account/login", :action => "login"
    account_map.signup "account/signup", :action => "signup", :conditions => { :method => :post }
    account_map.logout "account/logout", :action => "logout"
    account_map.activate "account/activate", :action => "activate"
  end
  
  map.with_options :controller => "about" do |about_map|
    about_map.about "about"
    about_map.help "about/help", :action => "help"
  end
  
  map.admin "admin", :controller => "admin"
  
  map.root :controller => "feed_items"
end
