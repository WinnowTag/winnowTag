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
        tag_control_for(feed_item, tag, classes_for_taggings(taggings, :stop))
      else
        if tagging = Array(taggings).first
          tag_control_for(feed_item, tag, classes_for_taggings(tagging, [:stop, :public]))
        end
      end
    end.compact.join(" ")
    
    content_tag(:ul, html, :class => "tag_list", :id => dom_id(feed_item, "tag_controls"))
  end
  
  # Format a classifier tagging strength as a percentage.
  def format_classifier_strength(taggings)
    if classifier_tagging = taggings.detect {|tagging| tagging.classifier_tagging? }
      "%.2f%" % (classifier_tagging.strength * 100)
    end
  end
  
  # Note: Update tagging.js when this changes
  def tag_control_for(feed_item, tag, classes)
    classes << "tag_control" << dom_id(tag)
    # TODO: sanitize
    content_tag(:li, content_tag(:span, h(tag.name), :class => "name"), :class => classes.join(" "), 
                     :onclick => "itemBrowser.selectTaggingInformation(this, #{tag.id})")
  end
  
  def tag_info_for(feed_item, tag, classifier_strength = nil)
    if tag.user == current_user
      training  = link_to_function(_(:positive_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'positive')", :class => "positive")
      training << link_to_function(_(:negative_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'negative')", :class => "negative")
      training << link_to_function(_(:remove_training_control),   "remove_tagging('#{dom_id(feed_item)}', #{tag.name.to_json})",          :class => "remove")
    else
      # TODO: sanitize
      training = content_tag(:div, "#{tag.user.firstname}<br/>#{tag.user.lastname}", :class => "owner")
    end
    
    clues_link = link_to_function "(clues)", "", :class => "clues_link"

    automatic  = content_tag(:span, "Negative<br/>Training #{clues_link}", :class => "negative")
    automatic << content_tag(:span, "Positive<br/>Training #{clues_link}", :class => "positive")
    automatic << content_tag(:span, content_tag(:span, classifier_strength, :class => "strength") + "Automatic<br/>Tag #{clues_link}", :class => "classifier")
    automatic  = content_tag(:span, automatic, :class => "status clearfix")    
    
    information  = content_tag(:div, training, :class => "training")
    information << content_tag(:div, automatic, :class => "automatic")
    information << content_tag(:div, "", :class => "clues", :style => "display: none")
    
    information
  end
  
	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
	  classes  = Array(classes)

    if tagging = taggings.first
      if tagging.classifier_tagging?
        classes << "classifier"
      elsif tagging.positive?
        classes << "positive"
      elsif tagging.negative?
        classes << "negative"
      end
    end
    
    if taggings.size > 1 && taggings.last(taggings.size - 1).detect(&:classifier_tagging?)
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
  
  def tags_for_sidebar
    tags = current_user.sidebar_tags + current_user.subscribed_tags - current_user.excluded_tags + 
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", params[:tag_ids].to_s.split(","), true, current_user])

    tags.uniq.sort_by { |tag| tag.name.downcase }
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
