# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module FeedsHelper
  def feed_link(feed)
    feed_link = link_to("Feed", feed.via, :class => "feed_icon replace")
    feed_home_link = feed.alternate ? 
                        link_to("Feed Home", feed.alternate, :class => "home_icon replace") : 
                        content_tag('span', '', :class => 'blank_icon replace')
                        
    feed_items_link = link_to _(:show), feed_items_path(:anchor => "feed_ids=#{feed.id}"), :class => 'show_icon replace', :title => _(:feeds_show_link_title, feed.title)
    # TODO: sanitize
    feed_page_link = link_to(feed.title, feed_path(feed), :id => dom_id(feed, "link_to"))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_items_link + ' ' + feed_page_link
  end
  
  def bookmarklet_js
    %|javascript:window.location='#{new_feed_url}?feed[url]='+window.location;|
  end
end
