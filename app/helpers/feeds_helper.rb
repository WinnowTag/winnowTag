# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module FeedsHelper
  # The +feed_link+ helper generated 3 icons, one a link to the original feed,
  # one a link to the feed's homepage, and one a link the view the feed items
  # for that feed in Winnow. The homepage icon/link may be blank if no homepage
  # link is know if the feed.
  def feed_link(feed)
    feed_link = link_to("Feed", feed.via, :target => "_blank", :title => t("winnow.items.main.feed_info_feed_tooltip"), :class => "feed")
    feed_home_link = feed.alternate ? 
                        link_to("Feed Home", feed.alternate, :target => "_blank", :title => t("winnow.items.main.feed_info_home_tooltip"), :class => "home") :
                        content_tag('span', '', :class => 'blank')

    feed_page_link = if params[:controller] == "feed_items"
      link_to_function(h(feed.title), "itemBrowser.addFilters({feed_ids: '#{feed.id}', feed_title: '#{feed.title}'})", :title => t("winnow.items.main.feed_info_only_items_tooltip"), :class => 'feed_filter_link')
    else
      link_to(h(feed.title), feed_items_path(:anchor => "feed_ids=#{feed.id}&feed_title=#{feed.title}"), :title => t("winnow.items.main.feed_info_only_items_tooltip"), :class => 'feed_filter_link')
    end
    
    feed_link + ' ' + feed_home_link + ' ' + feed_page_link
  end
  
  def bookmarklet_js
    "javascript:window.location='#{feeds_url}?feed[url]='+encodeURIComponent(window.location);"
  end
end
