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

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  # +ExceptionNotifiable+ is used to email the development team
  # when runtime errors occur in the production version of Winnow.
  include ExceptionNotifiable
  include AuthenticatedSystem
  
  # +controller_name+ and +action_name+ are needed by helpers to 
  # implement the selecting of the current tab.
  helper_method :controller_name, :action_name
  
  # See the definition of the methods below to learn about each of these before_filters.
  before_filter :login_from_cookie, :login_required, :set_time_zone, :update_access_time, :check_if_user_must_update_password

protected
  # This checks if there is an atom error. If there is an atom parse error
  # in config/initializers/mime_types.rb it will be stored in params[:atom_error].
  #
  def check_atom
    render(:text => h(params[:atom_error].message), :status => 400) if params[:atom_error]
  end
  
  # The +limit+ method returns the number of records to display
  # per page. If not limit is requested, it will return the default
  # limit of 40, and if a limit is request, it will ensure that it 
  # is more that the maximum limit of 100.
  def limit
    default_limit = 80
    max_limit = 100
    (params[:limit] ? [params[:limit].to_i, max_limit].min : default_limit)
  end

  # The +set_time_zone+ before filter is used to set the timezone
  # to use for this request based on the logged in user. Winnow
  # by default uses the UTC timezone, however each user can choose
  # which timezone they want to see all dates in.
  def set_time_zone
    if current_user && !current_user.time_zone.blank?
      Time.zone = current_user.time_zone
    # elsif cookies[:tzoffset].any?
    #   # current_user.update_attribute(:time_zone, browser_timezone.name) unless browser_timezone.name == current_user.time_zone
    #   Time.zone = TimeZone[-cookies[:tzoffset].to_i.minutes]
    end
  end

  # The +update_access_time+ before filter is used to record the 
  # latest time a user accessed any page in Winnow.
  def update_access_time
    if current_user
      current_user.update_attribute(:last_accessed_at, Time.now)
    end
  end

  # The +check_if_user_must_update_password+ is used to keep the 
  # user from using winnow until they set their password. Currently,
  # this is only used after logging in from a password reminder link.
  def check_if_user_must_update_password
    if session[:user_must_update_password]
      flash[:warning] = t("winnow.notifications.update_password")
      redirect_to edit_password_path
    end
  end

  def notify_of_tag_subscription_changes
    if current_user && request.format.html?
      flash.now[:stay_notice] = "" unless flash.now[:stay_notice];
      current_user.tag_subscriptions.each { |tag_subscription|
        if tag_subscription.original_creator
          flash.now[:stay_notice] = flash.now[:stay_notice] + t("winnow.general.tag_archive_notice", :original_creator => tag_subscription.original_creator, :tag_name => tag_subscription.tag.name)
          tag_subscription.clear_original_creator;
        end
        if tag_subscription.original_name
          flash.now[:stay_notice] = flash.now[:stay_notice] + t("winnow.general.tag_rename_notice", :user => tag_subscription.tag.user.login, :original_name => tag_subscription.original_name, :new_name => tag_subscription.tag.name)
          tag_subscription.clear_original_name;
        end
      }
    end
  end
end
