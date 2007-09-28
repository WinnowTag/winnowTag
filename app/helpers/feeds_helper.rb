# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedsHelper
  def feed_link(feed)
    feed_page_link = if feed.link and feed.title
        link_to(feed.title, feed.link)
      elsif feed.title
        feed.title
      elsif feed.link
        link_to(feed.link, feed.link)
      else
        feed.url
      end
      
    link_to(image_tag('feed_icon.png', :size => '14x14', :class => 'feed_icon'), feed.url) + ' ' + feed_page_link
  end
  
  def activate_feed_control(feed)
    check_box_tag("activate[#{feed.id}]", true, feed.active?, :id => "activate_#{feed.id}",
                    :disabled => !permit?('admin')) +
		  observe_field("activate_#{feed.id}", :url => {:action => 'update', :id => feed},
		 		            :with => "'feed[active]=' + $('activate_#{feed.id}').checked")
  end
end
