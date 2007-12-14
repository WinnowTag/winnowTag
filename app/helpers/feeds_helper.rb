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
  
  def globally_exclude_check_box(feed)
    check_box_tag feed.dom_id("globally_exclude"), "1", 
                  current_user.globally_excluded?(feed), 
                  :onclick => remote_function(
                                :url => globally_exclude_feed_path(feed), 
                                :with => "{ globally_exclude: this.checked }"
                              )
  end
  
  def always_include_feed_filter_control(feed)
    filter_control "Always Include This Feed", :include, @view.feed_filters.includes?(:always_include, feed), 
			      :id => feed.dom_id("always_include"), :disabled => current_user.globally_excluded?(feed),
			      :add_url => add_feed_view_path(@view, :feed_id => feed, :feed_state => "always_include"), 
			      :remove_url => remove_feed_view_path(@view, :feed_id => feed)    
  end
  
  def always_exclude_feed_filter_control(feed)
    filter_control "Always Exclude This Feed", :exclude, @view.feed_filters.includes?(:exclude, feed), 
			      :id => feed.dom_id("exclude"), :disabled => current_user.globally_excluded?(feed),
			      :add_url => add_feed_view_path(@view, :feed_id => feed, :feed_state => "exclude"), 
			      :remove_url => remove_feed_view_path(@view, :feed_id => feed)
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
