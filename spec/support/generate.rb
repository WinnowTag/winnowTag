# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Generate
  def self.comment(attributes = {})
    Comment.new(:tag_id => 1, :user_id => 1, :body => "Example body")
  end
end