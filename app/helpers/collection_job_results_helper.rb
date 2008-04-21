# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module CollectionJobResultsHelper
  def flash_collection_job_result
    if result = current_user.collection_job_result_to_display
      result.update_attribute(:user_notified, true)
      if result.failed?
        current_user.messages.create!(:body => _(:collection_failed, result.feed_title, result.message))
      else
        current_user.messages.create!(:body => _(:collection_finished, result.feed_title))
      end
    end
  end
end
