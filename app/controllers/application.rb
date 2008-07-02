# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '3515f89b854864c39e0c014d7128f740'
  
  include ExceptionNotifiable
  include AuthenticatedSystem
  helper_method :render_to_string, :controller_name, :action_name
  
  before_filter :login_from_cookie, :login_required, :set_time_zone, :update_access_time

  DEFAULT_LIMIT = 40 unless defined?(DEFAULT_LIMIT)
  MAX_LIMIT = 100 unless defined?(MAX_LIMIT)

protected
  # TODO: sanitize
  def check_atom
    render(:text => params[:atom_error].message, :status => 400) if params[:atom_error]
  end
  
  def local_request?
    ["216.176.191.98", "216.176.189.36", "127.0.0.1", "75.101.137.236"].include?(request.remote_ip)
  end

  def set_time_zone
    if current_user && !current_user.time_zone.blank?
      Time.zone = current_user.time_zone
    # elsif cookies[:tzoffset].any?
    #   # current_user.update_attribute(:time_zone, browser_timezone.name) unless browser_timezone.name == current_user.time_zone
    #   Time.zone = TimeZone[-cookies[:tzoffset].to_i.minutes]
    end
  end

  def update_access_time
    if current_user
      current_user.update_attribute(:last_accessed_at, Time.now)
    end
  end
end
