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


# Handles recording collection job results from the collector for
# collection jobs initiated manually by the user.
class CollectionJobResultsController < ApplicationController
  skip_before_filter :login_required
  with_auth_hmac HMAC_CREDENTIALS['collector']
  
  # Creates a collection job result for the user.
  def create
    user = User.find_by_login(params[:user_id]) || User.find(params[:user_id])
    feed = Feed.find_by_id(params[:collection_job_result][:feed_id]) || Remote::Feed.find(params[:collection_job_result][:feed_id])
    
    if params[:collection_job_result][:failed].to_s =~ /true/i
      user.messages.create!(:body => t("winnow.notifications.collection_failed", :title => feed.title, :message => params[:collection_job_result][:message]))
    end
    
    render :nothing => true, :status => :created
  end
end