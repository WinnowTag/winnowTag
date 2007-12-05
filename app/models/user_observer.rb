# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    # UserNotifier.deliver_signup_notification(user) unless user.recently_activated?
  end

  def after_save(user)
    # UserNotifier.deliver_activation(user) if user.recently_activated?
  end
end
