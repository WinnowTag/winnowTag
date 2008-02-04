# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedsHelper
  def feed_link(feed)
    feed_link = link_to("Feed", feed.via, :class => "feed_icon replace")
    feed_home_link = feed.alternate ? 
                        link_to("Feed Home", feed.alternate, :class => "home_icon replace") : 
                        content_tag('span', '', :class => 'blank_icon replace')
    feed_page_link = link_to((feed.title.blank? ? feed.via : feed.title), feed_path(feed))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def bookmarklet_js
    "javascript:" +
    "var f = document.createElement('form'); f.setAttribute('method', 'POST');" +
      "f.setAttribute('action', '#{feeds_url}'); f.style.display = 'none';" +
    "var m = document.createElement('input'); m.setAttribute('type', 'hidden');" +
      "m.setAttribute('name', 'feed[url]'); m.setAttribute('value', location.href);" +
      "f.appendChild(m); document.body.appendChild(f); f.submit();"    
  end
end
