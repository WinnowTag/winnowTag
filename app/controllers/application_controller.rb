# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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

  # Helper to handle conditional rendering based on last modified headers.
  #
  # This should probably be removed because it is now support in Rails
  # see http://ryandaigle.com/articles/2008/10/25/what-s-new-in-edge-rails-even-better-conditional-get-support
  #
  def conditional_render(last_modified)   
    since = Time.rfc2822(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil

    if since && last_modified && since >= last_modified
      head :not_modified
    else
      response.headers['Last-Modified'] = last_modified.httpdate if last_modified
      yield(since)
    end
  end
  
  # The +limit+ method returns the number of records to display
  # per page. If not limit is requested, it will return the default
  # limit of 40, and if a limit is request, it will ensure that it 
  # is more that the maximum limit of 100.
  def limit
    default_limit = 40
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
end
