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

class FeedManager < Manager

  # The +create+ method adds communicates with the Collector via the
  # +Remote::Feed+ model.
  # 
  # If the feed requested to be added does not exist in the Collector,
  # it is added.
  # 
  # A request to collect the feed is sent to the Collector.
  # 
  # The Feed is created locally so it is immediately available to the
  # user who requested it. The Collector will push additional information
  # to Winnow once it has collected it.
  # 
  # A FeedSubscription is created for the Feed and the user who requested it.
  def create(current_user, feed_url, collection_job_results_url)
    remote_feed = Remote::Feed.find_or_create_by_url_and_created_by(feed_url, current_user.login)

    if remote_feed.valid?
      remote_feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url)
      
      begin
        message = if feed = Feed.find_by_uri(remote_feed.uri)
          t("winnow.notifications.feed_existed", :url => h(feed.via))
        else feed = Feed.create!(:uri => remote_feed.uri, :via => remote_feed.url)
          t("winnow.notifications.feed_added", :url => h(feed.via))
        end
      rescue ActiveRecord::StatementInvalid => e
        feed = Feed.find_by_uri(remote_feed.uri)
        message = t("winnow.notifications.feed_added", :url => h(feed.via))
      end
      
      Multiblock[:success, feed, message]
    else
      Multiblock[:failed, remote_feed, remote_feed.errors.full_messages.to_sentence]
    end
  end
end
