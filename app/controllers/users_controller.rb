# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class UsersController < ApplicationController
  permit 'admin'
  before_filter :setup_user, :except => [:create, :new]
  
  def index
    add_to_sortable_columns('users', :field => 'login')
    add_to_sortable_columns('users', :field => 'lastname, firstname', :alias => "name")
    add_to_sortable_columns('users', :field => 'email')
    add_to_sortable_columns('users', :field => 'logged_in_at')
    add_to_sortable_columns('users', :field => 'last_accessed_at')
    add_to_sortable_columns('users', :field => 'last_tagging_on')
    add_to_sortable_columns('users', :field => 'tag_count')

    @users = User.search(:per_page => 20, :page => params[:page], :order => sortable_order('users', :alias => 'login', :sort_direction => :asc))
  end

  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    @user.save!
    @user.activate
    redirect_to :action => 'index'
  rescue
    render :action => 'new'
  end
  
  def show  
  end

  # currently don't support updates by admins
  def update      
    redirect_to :action => 'show'
  end

  def login_as
    self.current_user = @user
    redirect_to('/')
  end

  def destroy
    @user.destroy
    redirect_to users_path
  end
  
private
  def setup_user
     if params[:id] =~ /^[\d]+$/    
       @user = User.find(params[:id]) 
     elsif params[:id]
       @user = User.find_by_login(params[:id])
     end
   end
end
