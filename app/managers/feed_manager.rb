# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class FeedManager < Manager
  def create(current_user, feed_url, collection_job_results_url)
    remote_feed = Remote::Feed.find_or_create_by_url_and_created_by(feed_url, current_user.login)

    if remote_feed.valid?
      remote_feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url)
    
      message = if feed = Feed.find_by_uri(remote_feed.uri)
        t("winnow.notifications.feed_existed", :url => h(feed.via))
      else feed = Feed.create!(:uri => remote_feed.uri, :via => remote_feed.url)
        t("winnow.notifications.feed_added", :url => h(feed.via))
      end
      
      FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
      
      Multiblock[:success, feed, message]
    else
      Multiblock[:failed, remote_feed, remote_feed.errors.full_messages.to_sentence]
    end
  end
end
