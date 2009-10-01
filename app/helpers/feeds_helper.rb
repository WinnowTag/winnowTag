# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module FeedsHelper
  # The +feed_link+ helper generated 3 icons, one a link to the original feed,
  # one a link to the feed's homepage, and one a link the view the feed items
  # for that feed in Winnow. The homepage icon/link may be blank if no homepage
  # link is know if the feed.
  def feed_link(feed)
    feed_link = link_to("Feed", feed.via, :target => "_blank", :class => "feed")
    feed_home_link = feed.alternate ? 
                        link_to("Feed Home", feed.alternate, :target => "_blank", :class => "home") : 
                        content_tag('span', '', :class => 'blank')

    feed_page_link = link_to(h(feed.title), feed_items_path(:anchor => "feed_ids=#{feed.id}"),  :target => "_blank")
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def bookmarklet_js
    "javascript:window.location='#{feeds_url}?feed[url]='+window.location;"
  end
end
