# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class DemoController < ActionController::Base
  include AuthenticatedSystem
  helper :date, :feed_items, :feeds
  before_filter :login_from_cookie, :redirect_logged_in_user
  
  def index
    @user = User.find_by_login("pw_demo")
    respond_to do |format|
      format.html
      format.json do
        @feed_items = FeedItem.find_with_filters(
                              :user => @user, 
                              :limit => 40, 
                              :offset => params[:offset],
                              :tag_ids => params[:tag_ids])
      end
    end
  end
  
  private
  def redirect_logged_in_user
    redirect_to feed_items_path if logged_in?
  end
end
