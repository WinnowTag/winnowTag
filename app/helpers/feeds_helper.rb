# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedsHelper
  def feed_link(feed)
    feed_link = link_to("Feed", feed.url, :class => "feed_icon replace")
    feed_home_link = feed.link ? 
                        link_to("Feed Home", feed.link, :class => "home_icon replace") : 
                        content_tag('span', '', :class => 'blank_icon replace')
    feed_page_link = link_to((feed.title or feed.url), feed_path(feed))
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def activate_feed_control(feed)
    check_box_tag("activate[#{feed.id}]", true, feed.active?, :id => "activate_#{feed.id}",
                    :disabled => !permit?('admin')) +
		  observe_field("activate_#{feed.id}", :url => {:action => 'update', :id => feed},
		 		            :with => "'feed[active]=' + $('activate_#{feed.id}').checked")
  end
end
