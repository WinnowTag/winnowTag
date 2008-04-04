# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module AboutHelper # :nodoc:
  def classifier_info(classifer_info)
    if @classifier_info 
      rev = "??"
      if @classifier_info.respond_to?(:git_revision)
        rev = @classifier_info.git_revision
      elsif @classifier_info.respond_to(:svnversion)        
        rev = @classifier_info.svnversion
      end
      
      content_tag('p',
          'Using classifier version ' +
          content_tag('span', @classifier_info.version, :class => 'classifier_version') +
          ' at build ' +
          content_tag('span', rev, :class => 'classifier_gitrevision') +
          '.',
          :class => 'classifier_info')
    else
      content_tag('p',
          'The classifer could not be contacted.',
          :class => 'classifier_error')
    end
  end  
end
