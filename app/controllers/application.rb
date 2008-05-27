# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '3515f89b854864c39e0c014d7128f740'

  include ExceptionNotifiable
  include AuthenticatedSystem
  helper_method :render_to_string, :controller_name, :action_name
  
  before_filter :login_from_cookie, :login_required

  DEFAULT_LIMIT = 40
  MAX_LIMIT = 100

protected
  def check_atom
    render(:text => params[:atom_error].message, :status => 400) if params[:atom_error]
  end
  
  def local_request?
    ["216.176.191.98", "216.176.189.36", "127.0.0.1"].include?(request.remote_ip)
  end
end
