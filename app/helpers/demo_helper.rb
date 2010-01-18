# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

module DemoHelper
  # The +feed_control_for+ generates the control to show/hide the feed information on a feed item/
  # This is displayed in the collapsed view of a feed item.
  def feed_title_for(feed_item)
    if feed_item.author.blank?
      t("winnow.items.main.feed_metadata", :feed_title => content_tag(:span, h(feed_item.feed_title), :class => "feed_title"))
    else
      t("winnow.items.main.metadata", :feed_title => content_tag(:span, h(feed_item.feed_title), :class => "feed_title"), :author => h(feed_item.author))
    end
  end
  
  def demo_tag_controls 
    @user.tags_for_sidebar.map do |tag|
      content_tag("li", tag.name, :id => dom_id(tag), 
                                  :class => "tag", 
                                  :title => tag.description, 
                                  :name => tag.name,
                                  :pos_count => tag.positive_count,
                                  :neg_count => tag.negative_count,
                                  :item_count => tag.feed_items_count)
    end.join
  end
end
