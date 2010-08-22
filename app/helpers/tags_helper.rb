# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module TagsHelper
  def created_by_tooltip(login)
    if login == "archive"
      t('winnow.tags.attributes.archive_user_tooltip')
    else
      t('winnow.tags.attributes.user_name_tooltip', :user_name => login)
    end
  end
end
