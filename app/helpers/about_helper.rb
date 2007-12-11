# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module AboutHelper # :nodoc:
  def classifier_info(classifer_info)
    if @classifier_info 
      content_tag('p',
          'Using classifier version ' +
          content_tag('span', @classifier_info.version, :class => 'classifier_version') +
          ' at build no ' +
          content_tag('span', @classifier_info.svnversion, :class => 'classifier_svnversion') +
          '.',
          :class => 'classifier_info')
    else
      content_tag('p',
          'The classifer could not be contacted.',
          :class => 'classifier_error')
    end
  end  
end
