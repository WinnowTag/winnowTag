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

require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  it "admin_required" do
    user = Generate.user!
    
    cannot_access(user, :get, :index)
    cannot_access(user, :get, :new)
    cannot_access(user, :post, :create)
    cannot_access(user, :delete, :destroy,  :id => user)
    cannot_access(user, :post, :login_as, :id => user)
  end
  
  it "index" do
    login_as Generate.admin!
    get :index
    assert_response :success
  end
  
  it "new" do
    login_as Generate.admin!
    get :new
    assert_response :success
    # TODO: Move to view test
    # assert_select "form[action=#{users_path}]"
  end
  
  describe '#create' do
    def do_post
      post :create, :user => @user_params
    end
    
    before(:each) do
      login_as Generate.admin!
      
      @user_params = "user params"
      @user = mock_model(User)

      User.stub!(:create_from_prototype).and_return(@user)
    end
    
    it "should create a new user from the prototype" do
      User.should_receive(:create_from_prototype).with(@user_params).and_return(@user)
      do_post
    end
    
    describe "success" do
      it "redirect to the index action" do
        @user.stub!(:new_record?).and_return(false)
        do_post
        response.should redirect_to(users_path)
      end
    end
    
    describe "fail" do
      before(:each) do
        @user.stub!(:new_record?).and_return(true)
      end

      it "assigns the user for the view" do
        do_post
        assigns(:user).should == @user
      end
      
      it "render the new template" do
        do_post
        response.should render_template("new")
      end
    end
  end
  
  it "login_as_changes_current_user_and_redirects_to_index" do
    user = Generate.user!
    
    login_as Generate.admin!
    post :login_as, :id => user.id
    assert_redirected_to('/')
    assert_equal user.id, session[:user]
  end
    
  it "destroy" do
    user = Generate.user!
    
    login_as Generate.admin!
    delete :destroy, :id => user.id
    assert_raise(ActiveRecord::RecordNotFound) { user.reload }
    assert_redirected_to users_path
  end
end
