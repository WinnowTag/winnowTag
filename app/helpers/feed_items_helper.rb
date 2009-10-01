# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
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

  # The +tag_controls+ helper generates the list of taggings applied to a feed item.
  # These are displayed in the collapsed view of a feed item.
  def tag_controls(feed_item)
    html = feed_item.taggings_to_display.map do |tag, taggings|
      if tag.user == current_user
        tag_control_for(feed_item, tag, classes_for_taggings(taggings), format_classifier_strength(taggings))
      else
        if tagging = Array(taggings).first
          tag_control_for(feed_item, tag, classes_for_taggings(tagging, [:public]), format_classifier_strength(tagging))
        end
      end
    end.compact.join(" ")
    
    content_tag(:ul, html, :class => "tag_list")
  end
  
  # Generates an individual tag tag control.
  # See FeedItemsHelper#tag_control_for.
  # Note: Update item.js when this changes.
  def tag_control_for(feed_item, tag, classes, strength)
    classes << "tag_control" << dom_id(tag) << "stop"
    content_tag(:li, content_tag(:span, h(tag.name), :class => "name", :"data-sort" => tag.sort_name), :class => classes.join(" "), :title => tag_control_tooltip(tag, strength))
  end
  
  # Generates the text for the tooltip displayed on the list of tags applied to a feed item.
  # See FeedItemsHelper#tag_control_for.
  def tag_control_tooltip(tag, strength)
    title = []
    title << "by #{h(tag.user.login)}" if tag.user_id != current_user.id
    title << "#{strength}" if strength
    title.join(", ") unless title.blank?
  end
  
  # Generates the classes that should exist on an individual tag control.
  # These are used to properly style the tagging.
  # See FeedItemsHelper#tag_control_for.
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
    if feed_item.author.blank?
      t("winnow.items.main.feed_metadata", :feed_title => content_tag(:a, h(feed_item.feed_title), :class => "feed_title stop"))
    else
      t("winnow.items.main.metadata", :feed_title => content_tag(:a, h(feed_item.feed_title), :class => "feed_title stop"), :author => h(feed_item.author))
    end
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
