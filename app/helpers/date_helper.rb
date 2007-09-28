# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module DateHelper
  def format_date(date, when_nil = "Never")
    if date.nil?
      when_nil
    else
      format = date.midnight == Time.now.utc.midnight ? "%H:%M %p" : "%b %d"        
      if current_user.tz
        date = current_user.tz.utc_to_local(date)
      end
      
      content_tag "nobr", date.strftime(format)      
    end
  end
end