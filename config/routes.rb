ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  
  map.resources :global_tag_groups
  map.resources :tag_publications, :path_prefix => '/tag_groups/:tag_group_id', :name_prefix => 'tag_group_'
  map.resources :tag_publications, :path_prefix => '/users/:user_id', :name_prefix => 'user_'
  
  map.resources :users, 
                :member => {
                  :login_as => :post
                }
                
  map.resources :feeds                              
  map.resources :feed_items, 
                :member => {
                  :inspect => :get,
                  :mark_read => :put,
                  :mark_unread => :put,
                  :info => :get,
                  :description => :get
                }
  map.resources :tags, :requirements => {:id => /.*/}
  
  map.resource :classifier, 
               :member => {
                 :status => :post,
                 :cancel => :post,
                 :classify => :post
               }
  map.resource :classifier, 
              :path_prefix => '/tag_publications/:tag_publication_id',
              :name_prefix => 'tag_pub_',
              :member => {
                :status => :any,
                :cancel => :post,
                :classify => :post
              }
              
  map.resources :collection_job_results, :path_prefix => '/users/:user_id'
  map.resource :item_protection, 
                :member => {
                  :rebuild => :post
                }
                
  map.resources :views, :member => { :add_feed => :post, :remove_feed => :post, :add_tag => :post, :remove_tag => :post, :duplicate => :post }
  
  map.login "/account/login", :controller => "account", :action => "login"
  map.logout "/account/logout", :controller => "account", :action => "logout"
  map.signup "/account/signup", :controller => "account", :action => "signup"
  map.edit_account "/account/edit/:id", :controller => "account", :action => "edit"
  
  map.about "/about", :controller => "about"
  map.help "/about/help", :controller => "about", :action => "help"

  map.admin "/admin", :controller => "admin"
  
  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "feed_items"
  
  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id', :requirements => {:id => /.*/}
end
