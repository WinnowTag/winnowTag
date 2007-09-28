# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module UsersHelper # :nodoc:
  def permission_checkbox(permission, status)
    check_box_tag("permissions[#{permission}]", "1", status, :id => "permission_#{permission}",
                    :disabled => !permit?('admin')) +
		  observe_field("permission_#{permission}", :url => {:action => 'update', :id => @user.login},
		 		            :with => "'permissions[#{permission}]=' + $('permission_#{permission}').checked",
		 		            :failure => 'alert(request.responseText)',
		 		            :success => visual_effect(:highlight, "permission_#{permission}_cell"),
		 		            :exception => 'alert("exception")')
  end
end
