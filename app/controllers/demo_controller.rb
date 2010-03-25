# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

class DemoController < ActionController::Base
  helper :date, :feed_items, :feeds
  
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
end
