# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module CommentsHelper
  def can_edit_comment?(comment)
    is_admin? || comment.user == current_user || comment.tag.user == current_user
  end
end
