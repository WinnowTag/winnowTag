# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module CollectionJobResultsHelper
  include FeedsHelper
  
  def flash_collection_job_result
    if result = current_user.collection_job_result_to_display
      result.update_attribute(:user_notified, true)
      if result.failed?
        flash[:warning] = "Collection Job for #{result.feed_title} failed with result: #{result.message}"
      else
        flash[:notice] = "The feed you requested '#{result.feed.title}' now has #{result.feed.feed_items.size} items."
      end
    end
  end
end
