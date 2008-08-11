# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module FeedsHelper
  def feed_link(feed)
    feed_link = link_to("Feed", feed.via, :target => "_blank", :class => "feed_icon replace")
    feed_home_link = feed.alternate ? 
                        link_to("Feed Home", feed.alternate, :target => "_blank", :class => "home_icon replace") : 
                        content_tag('span', '', :class => 'blank_icon replace')

    # TODO: sanitize
    feed_page_link = link_to(feed.title, feed_items_path(:anchor => "feed_ids=#{feed.id}"),  :target => "_blank", :id => dom_id(feed, "link_to"))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def bookmarklet_js
    %|javascript:window.location='#{new_feed_url}?feed[url]='+window.location;|
  end
end
