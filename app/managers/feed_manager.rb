# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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
      
      feed, message = nil, nil
      Feed.transaction do
        message = if feed = Feed.find_by_uri(remote_feed.uri)
          t("winnow.notifications.feed_existed", :url => h(feed.via))
        else feed = Feed.create!(:uri => remote_feed.uri, :via => remote_feed.url)
          t("winnow.notifications.feed_added", :url => h(feed.via))
        end
      end
      
      FeedSubscription.find_or_create_by_feed_id_and_user_id(feed.id, current_user.id)
      
      Multiblock[:success, feed, message]
    else
      Multiblock[:failed, remote_feed, remote_feed.errors.full_messages.to_sentence]
    end
  end
end
