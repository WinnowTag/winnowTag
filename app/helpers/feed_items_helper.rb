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

module FeedItemsHelper
  # The +feed_item_title+ helper prints out the feed items title, or the
  # default text when no title exists for the feed item.
  def feed_item_title(feed_item)
    if feed_item.title.blank?
      content_tag :span, t("winnow.items.main.no_title"), :class => "notitle"
    else
      h(feed_item.title)
    end
  end
  
  def current_tag_training(feed_item)
    if feed_item.tagged_type.nil?
      ""
    elsif feed_item.tagged_type.to_i == 1
      "positive"
    elsif feed_item.tagged_type.to_i == 0
      "negative"
    else
      ""
    end
  end

  # Generates the text for the tooltip displayed on the list of tags applied to a feed item.
  def tag_control_tooltip(tag, strength, taggings_classes)
    title = []
    title << "by #{h(tag.user.login)}" if tag.user_id != current_user.id
    if taggings_classes.include?("positive")
      title << t("winnow.items.main.moderation_panel_positive_tag_tooltip", :tag_name => tag.name)
    elsif taggings_classes.include?("negative")
      title << t("winnow.items.main.moderation_panel_negative_tag_tooltip", :tag_name => tag.name)
    elsif strength
      title << t("winnow.items.main.moderation_panel_classifier_tag_tooltip", :strength => strength, :tag_name => tag.name)
    else
      title << t("winnow.items.main.moderation_panel_no_tag_tooltip", :tag_name => tag.name)
    end
    title.join(", ") unless title.blank?
  end
  
  # Generates the classes that should exist on an individual tag control.
  # These are used to properly style the tagging.
	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
	  classes  = Array(classes)

    if taggings.detect { |t| t.positive? && !t.classifier_tagging? }
      classes << "positive"
    end
    if taggings.detect { |t| t.negative? && !t.classifier_tagging? }
      classes << "negative"
    end
    if taggings.detect { |t| t.classifier_tagging? }
      classes << "classifier"
    end

    classes.uniq
  end
  
  # The +feed_control_for+ generates the control to show/hide the feed information on a feed item/
  # This is displayed in the collapsed view of a feed item.
  def feed_control_for(feed_item)
    t("winnow.items.main.feed_metadata", :feed_title => content_tag(:a, h(feed_item.feed_title), :title => t("winnow.items.main.feed_info_control_tooltip"), :class => "feed_title stop"))
  end
  
  # Formats a classifier tagging strength as a percentage.
  def format_classifier_strength(taggings)
    taggings = Array(taggings)
    
    if classifier_tagging = taggings.detect { |tagging| tagging.classifier_tagging? }
      "%.2f%" % (classifier_tagging.strength * 100)
    end
  end
  
  # Fetches the list of feeds that should be displayed in the sideabr.
  # Currently, this is the list of feeds the user is subscribed to, 
  # excluding any globally excluded feeds, and including any feeds which 
  # are being specificaly requested right now.
  def feeds_for_sidebar
    feeds = current_user.feeds
    feed_ids = params[:feed_ids].to_s.split(",").map(&:to_i) - feeds.map(&:id)
    feeds += Feed.find_all_by_id(feed_ids) unless feed_ids.empty?
    feeds.sort_by { |feed| feed.sort_title }
  end
end
