# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +UsersController+ is only accessible by admin users. Admins use
# this controller to view the users in the system, add new users, 
# remove users, login as other user, and manage the prototype user 
# which will be used to create new accounts
class UsersController < ApplicationController
  permit 'admin'

  # See the definition of +find_user+ below to learn this before_filter.
  before_filter :find_user, :except => [:create, :new]
  
  # See FeedItemsController#index for an explanation of the html/json requests.
  def index
    respond_to do |format|
      format.html
      format.json do
        @users = User.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction],
                             :limit => limit, :offset => params[:offset])
        @full = @users.size < limit
      end
      # The csv request is used to export the current list of users to a CSV document.
      format.csv do
        @users = User.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction])
      end
    end
  end

  def new
    @user = User.new
  end
  
  # The +create+ action will create a nwe user account based on the 
  # prototype. This new user account will be activated and ready to use.
  def create
    @user = User.create_from_prototype(params[:user])
    unless @user.new_record?
      redirect_to users_path
    else
      render :action => 'new'
    end
  end

  # The +prototype+ action is used to set a specific user as the prototype
  # which new accounts should be based on.
  def prototype
    @user.update_attribute :prototype, true
    redirect_to :back
  end
  
  # The +login_as+ action isused to allow an admin to login to another users
  # account.
  def login_as
    self.current_user = @user
    redirect_to root_path
  end

  def destroy
    @user.destroy
    redirect_to users_path
  end
  
private
  # The +find_user+ before_filter will inspect the +id+ parameter
  # and find the user based on id or login, depending on what is
  # contained in the +id+ parameter.
  def find_user
    if params[:id] =~ /^[\d]+$/    
      @user = User.find(params[:id]) 
    elsif params[:id]
      @user = User.find_by_login(params[:id])
    end
  end
end
