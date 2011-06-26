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


class DemoController < ActionController::Base
  include AuthenticatedSystem
  helper :date, :feed_items, :feeds
  before_filter :login_from_cookie, :redirect_logged_in_user
  
  def index
    @user = User.find_by_login("pw_demo")
    respond_to do |format|
      format.html
      format.json do
        params[:tag_ids].to_s.split(",").each do |tag_id|
          if tag = Tag.find_by_id(tag_id)
            @tag = tag; # Make the currently selected tag available to the view
          end
        end

        @feed_items = FeedItem.find_with_filters(
                              :user => @user, 
                              :limit => 80,
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
