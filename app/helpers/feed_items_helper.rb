# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module FeedItemsHelper
  include BiasSliderHelper
  
  def link_to_feed(feed, options = {})
    # TODO: sanitize
    if feed.alternate
      link_to(feed.title, feed.alternate, options.merge(:target => "_blank"))
    else
      feed.title
    end
  end
  
  def link_to_feed_item(feed_item, options = {})
    if feed_item.link 
      link_to(feed_item_title(feed_item), feed_item.link, options.merge(:target => "_blank"))
    else
      feed_item_title(feed_item)
    end
  end
  
  def feed_item_title(feed_item)
    # TODO: sanitize
    if not feed_item.title.blank?
      feed_item.title
    else
      content_tag :span, _(:feed_item_no_title), :class => "notitle"
    end
  end
    
  # Creates the classification button.
  #
  # When pressed, the classification button creates a Classification
  # Javascript object that handles the interaction with the server.
  # See Classification and Classification.startItemBrowserClassification
  # in classification.js.
  #
  # The way the routes are setup for the classifier controller means
  # that we can always identify a single classifier to use by either
  # a prefix path, as in the case of a tag publications classifier 
  # or using '/classifier' which is the classifier belonging
  # to the current user.
  #
  def classification_button
    button_to_function _(:start_classifier_button), "Classification.startItemBrowserClassification(#{classifier_path.to_json});", :id => 'classification_button'
  end
  
  def cancel_classification_button
    button_to_function(_(:stop_classifier_button), 'Classification.cancel();', :style => "display: none", :id => 'cancel_classification_button')
  end
  
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
    
    content_tag(:ul, html, :class => "tag_list", :id => dom_id(feed_item, "tag_controls"))
  end
  
  def feed_control_for(feed_item)
    if feed_item.author.blank?
      _(:feed_item_feed_metadata, content_tag(:a, feed_item.feed_title, :class => "name stop", :onclick => "itemBrowser.selectFeedInformation(this)"))
    else
      _(:feed_item_metadata, content_tag(:a, feed_item.feed_title, :class => "name stop", :onclick => "itemBrowser.selectFeedInformation(this)"), feed_item.author)
    end
  end
  
  # Format a classifier tagging strength as a percentage.
  def format_classifier_strength(taggings)
    taggings = Array(taggings)
    
    if classifier_tagging = taggings.detect {|tagging| tagging.classifier_tagging? }
      "%.2f%" % (classifier_tagging.strength * 100)
    end
  end
  
  # Note: Update tagging.js when this changes
  def tag_control_for(feed_item, tag, classes, strength)
    classes << "tag_control" << dom_id(tag) << "stop"
    # TODO: sanitize
    content_tag(:li, content_tag(:span, h(tag.name), :class => "name"), :class => classes.join(" "), :title => tag_control_tooltip(tag, strength))
  end
  
  def tag_control_tooltip(tag, strength)
    title = []
    title << "by #{tag.user.display_name}" if tag.user_id != current_user.id
    title << "#{strength}" if strength
    title.join(", ") unless title.blank?
  end
  
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
  
  def feeds_for_sidebar
    feeds = current_user.feeds
    feed_ids = params[:feed_ids].to_s.split(",").map(&:to_i) - feeds.map(&:id)
    feeds += Feed.find_all_by_id(feed_ids) unless feed_ids.empty?
    feeds.sort_by { |feed| feed.title.downcase }
  end

  def render_clues(clues)
    sorted_grouped_clues = clues.sort_by { |clue| clue['prob'] }.reverse.in_groups_of((clues.size.to_f / 3).ceil)
    content_tag('table') do
      clue_header +
      sorted_grouped_clues.shift.zip(*sorted_grouped_clues).map do |clues|
        render_clue_row(clues)
      end.join
    end
  end
  
  def clue_header
    content_tag('tr', 
      (content_tag('th', 'Clue', :class => "clue") + content_tag('th', 'Prob', :class => "prob")) * 3
    )
  end
  
  def render_clue_row(clue_row)
    content_tag('tr') do
      clue_row.map do |clue|
        render_clue(clue)
      end.join
    end
  end
  
  def render_clue(clue)
    if clue
      content_tag('td', clue['clue'], :class => 'clue') + content_tag('td', clue['prob'], :class => 'prob')
    else
      content_tag('td', nil, :class => 'clue') + content_tag('td', nil, :class => 'prob')
    end
  end
end
