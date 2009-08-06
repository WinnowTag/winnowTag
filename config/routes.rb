ActionController::Routing::Routes.draw do |map|
  map.namespace :item_cache do |item_cache|
    item_cache.resources :feed_items, :only => [:create, :update, :destroy], :requirements => {:id => %r{[^/;,?]+}}
    item_cache.resources :feeds, :only => [:create, :update, :destroy], :requirements => {:id => %r{[^/;,?]+}} do |feeds|
      feeds.resources :feed_items, :only => [:create, :update, :destroy], :requirements => {:feed_id => %r{[^/;,?]+}, :id => %r{[^/;,?]+}}
    end
  end

  map.resources :invites, :except => :show,
                :member => {
                  :activate => :put
                }

  map.resources :users, :only => [:index, :new, :create, :destroy],
                :member => {
                  :login_as => :post,
                  :prototype => :put
                }

  map.resources :feeds, :only => [:index, :create],
                :member => {
                  :globally_exclude => :post,
                  :subscribe => :put
                },
                :collection => {
                  :auto_complete_for_feed_title => :any,
                  :import => :any
                }

  map.resources :feed_items, :only => :index,
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
                  :mark_unread => :put,
                  :sidebar => :get
                }                

  map.with_options :controller => "tags" do |tags_map|
    tags_map.connect ":user/tags.:format", :action => 'index'
    tags_map.connect ":user/tags/:tag_name.:format", :action => 'show'
    tags_map.connect ":user/tags/:tag_name/:action.:format"
  end

  map.resources :tags, :only => [:index, :show, :create, :update, :destroy],
                :collection => { 
                  :public => :get,
                  :auto_complete_for_sidebar => :any,
                  :upload => :post
                },
                :member => { 
                  :globally_exclude => :post,
                  :publicize => :put, 
                  :subscribe => :put,
                  :unsubscribe => :put, 
                  :sidebar => :put,
                  :training => :get,
                  :information => :get,
                  :classifier_taggings => [:post, :put],
                  :merge => :put,
                  :comments => :get
                }

  map.resources :taggings, :only => [:create] #, :collection => { :destroy => :delete } # This does not work, so we will do it manually below
  map.destroy_taggings '/taggings', :controller => 'taggings', :action => 'destroy', :conditions => { :method => :delete }

  map.resource :classifier, :controller => "classifier", :only => [],
               :member => {
                 :status => :post,
                 :classify => :post
               }
              
  map.resources :collection_job_results, :path_prefix => '/users/:user_id', :only => :create

  map.resources :folders, :only => [:create, :update, :destroy],
                :member => {
                  :add_item => :put,
                  :remove_item => :put
                },
                :collection => {
                  :sort => :put
                }

  map.resources :messages, :except => :show
  map.resources :feedbacks, :only => [:index, :new, :create]
  map.resources :comments, :only => [:create, :edit, :update, :destroy]

  map.with_options :controller => "account" do |account_map|
    account_map.edit_account "account/edit", :action => "edit"
    account_map.edit_password "account/password", :action => "edit_password"
    account_map.login "account/login/:code", :action => "login", :code => nil, :requirements => { :code => /.*/ } # the requirements seems to get rid of the trailing slash when using login_path
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
  
  map.connect 'public/ie6', :controller => "public", :action => "ie6"
  map.root :info
end
