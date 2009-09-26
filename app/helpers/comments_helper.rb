# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module CommentsHelper
  # Users can only edit a comment if they are an admin, they made the comment,
  # or they are the owner of the tag.
  def can_edit_comment?(comment)
    is_admin? || comment.user == current_user || comment.tag.user == current_user
  end
end
