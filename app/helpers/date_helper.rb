# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module DateHelper
  def format_date(date, when_nil = t("winnow.general.never"))
    if date.nil?
      when_nil
    else
      format = date.midnight == Time.zone.now.midnight ? "%H:%M %p" : "%e %b, %y"
      date.strftime(format)
    end
  end
end
