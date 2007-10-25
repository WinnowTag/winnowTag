# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class UsersController < ApplicationController
  permit 'admin'
  before_filter :setup_user, :except => [:create, :new]
  verify :except => [:index, :new, :create], :params => :id, :redirect_to => {:action => ''},
          :add_flash => {:error => 'action requires a user id'}
  verify :only => [:destroy], :method => :delete, :redirect_to => {:action => ''},
          :add_flash => {:error => 'destroy requires delete'}
  verify :only => :login_as, :method => :post, :redirect_to => {:action => ''},
          :add_flash => {:error => 'login_as requires post'}
  
  def index
    @user_pages, @users = paginate(:users, :order => 'lastname, firstname', :per_page => 20)
  end

  def new
    @user = User.new()
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
    redirect_to :action => ''
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
