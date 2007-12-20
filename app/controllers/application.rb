# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '3515f89b854864c39e0c014d7128f740'

  include ExceptionNotifiable
  include AuthenticatedSystem
  before_filter :login_from_cookie, :login_required, :load_view
  SHOULD_BE_POST = {
        :text => 'Bad Request. Should be POST. ' +
                 'Please report this bug. Make ' +
                 'sure you have Javascript enabled too! ', 
        :status => 400
      }
  MISSING_PARAMS = {
        :text => 'Bad Request. Missing Parameters. ' +
                 'Please report this bug. Make ' +
                 'sure you have Javascript enabled too! ', 
        :status => 400
      }
      
protected
  def local_request?
    [["216.176.191.98"] * 2, ["127.0.0.1"] * 2].include?([request.remote_addr, request.remote_ip])
  end
  
  def load_view
    if current_user
      if params[:view_id]
        if params[:view_id] == "new"
          if request.get?
            @view = current_user.views.create!
            flash.keep
            redirect_to params.merge(:view_id => @view)
          end
        else
          @view = current_user.views.find(params[:view_id])
          @view.set_as_default!
        end
      elsif @view = current_user.views.default
        if request.get?
          flash.keep
          redirect_to params.merge(:view_id => @view)
        end
      else
        @view = current_user.views.create!
        if request.get?
          flash.keep
          redirect_to params.merge(:view_id => @view)
        end
      end
    end
  end
end
