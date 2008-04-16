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
    respond_to do |format|
      format.html
      format.js do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)
        @users, @users_count = User.search(:text_filter => params[:text_filter], 
                                           :order => params[:order], :direction => params[:direction],
                                           :limit => limit, :offset => params[:offset], :count => true)
      end
      format.csv do
        @users = User.search(:text_filter => params[:text_filter], :order => params[:order])
      end
    end
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
