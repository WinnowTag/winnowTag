# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module AboutHelper # :nodoc:
  def classifier_info(classifier_info)
    if classifier_info
      content_tag('p', t("winnow.about.classifier_info", :version => classifier_info.version, :build => classifier_info.git_revision), :class => 'classifier_info')
    else
      content_tag('p', t("winnow.about.classifier_info_not_found"), :class => 'classifier_error')
    end
  end  
end
