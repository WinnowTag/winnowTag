# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


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
