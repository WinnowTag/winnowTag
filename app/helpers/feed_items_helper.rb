# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module FeedItemsHelper
  include BiasSliderHelper
  
  def link_to_feed(feed, options = {})
    # TODO: sanitize
    if feed.alternate
      link_to(feed.title, feed.alternate, :target => "_blank") 
    else
      feed.title
    end
  end
  
  def link_to_feed_item(feed_item)
    # TODO: sanitize
    if feed_item.link 
      link_to(feed_item.title, feed_item.link, :target => "_blank") 
    else
      feed_item.title
    end
  end
  
  def toggle_read_unread_button
    # TODO: localization
    link_to_function "", "itemBrowser.toggleReadUnreadItem(this.up('.item'))", 
      :onmouseover => "this.title = 'Click to mark as ' + ($(this).up('.item').match('.read') ? 'unread' : 'read');"
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
        tag_control_for(feed_item, tag, classes_for_taggings(taggings, [:stop]), format_classifier_strength(taggings))
      else
        if tagging = Array(taggings).first
          tag_control_for(feed_item, tag, classes_for_taggings(tagging, [:stop, :public]), format_classifier_strength(taggings))
        end
      end
    end.compact.join(" ")
    
    content_tag(:ul, html, :class => "tag_list", :id => dom_id(feed_item, "tag_controls"))
  end
  
  # Format a classifier tagging strength as a percentage.
  def format_classifier_strength(taggings)
    if classifier_tagging = taggings.detect {|t| t.classifier_tagging? }
      "%.2f%" % (classifier_tagging.strength * 100)
    end
  end
  
  # Note: Update tagging.js when this changes
  def tag_control_for(feed_item, tag, classes, classifier_strength)
    information_id = dom_id(feed_item, "tag_info_for_#{tag.name}_on")
    clues_id = "feed_item_#{feed_item.id}_tag_#{tag.id}_clues"

    clues_link = link_to_remote("(clues)", :url => clues_feed_item_path(feed_item, :tag => tag), :method => :get,
                                           :before => "$('#{clues_id}').addClassName('loading')", 
                                           :complete => "$('#{clues_id}').removeClassName('loading')")

    # TODO: sanitize
    content = content_tag(:span, h(tag.name), :class => "name", 
                            :onclick => "show_tagging_information(this, #{information_id.to_json}, #{tag.name.to_json}, #{classifier_strength.to_json}, #{clues_link.to_json});")
    
    classes << "tag_control"
    
    # TODO: sanitize
    content_tag(:li, content, :id => dom_id(feed_item, "tag_control_for_#{tag.name}_on"), :class => classes.join(" "))
  end
  
  def tag_infos(feed_item)
    html = feed_item.taggings_to_display.map do |tag, taggings|
      if tag.user == current_user
        tag_info_for(feed_item, tag, classes_for_taggings(taggings))
      else
        if tagging = Array(taggings).first
          tag_info_for(feed_item, tag, classes_for_taggings(tagging, [:public]))
        end
      end
    end.compact.join(" ")
    
    content_tag(:div, html)
  end

  def tag_info_for(feed_item, tag, classes)
    information_id = dom_id(feed_item, "tag_info_for_#{tag.name}_on")
    clues_id = "feed_item_#{feed_item.id}_tag_#{tag.id}_clues"

    if tag.user == current_user
      training  = link_to_function(_(:positive_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'positive')", :class => "positive")
      training << link_to_function(_(:negative_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'negative')", :class => "negative")
      training << link_to_function(_(:remove_training_control),   "remove_tagging('#{dom_id(feed_item)}', #{tag.name.to_json})",          :class => "remove")
    else
      # TODO: sanitize
      training = content_tag(:div, "#{tag.user.firstname}<br/>#{tag.user.lastname}", :class => "owner")
    end
    
    automatic  = content_tag(:span, nil, :class => "status clearfix")    
    
    information  = content_tag(:div, training, :class => "training")
    information << content_tag(:div, automatic, :class => "automatic")
    information << content_tag(:div, nil, :id => clues_id, :class => "clues")
    
    classes << "information" << "clearfix"
    
    content_tag(:div, information, :id => information_id, :class => classes.join(" "))
  end
  
	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
    
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
  
  def feed_item_title(feed_item)
    # TODO: sanitize
    if not feed_item.title.blank?
      feed_item.title
    else
      content_tag :span, _(:feed_item_no_title), :class => "notitle"
    end
  end
  
  def render_clues(clues)
    content_tag('table') do
      clue_header +
      clues.sort_by {|clue| clue['prob'] }.reverse.map do |clue|
        render_clue_row([clue])
      end.join
    end
  end
  
  def clue_header
    content_tag('tr', 
      content_tag('th', 'Clue') +
      content_tag('th', 'Prob')
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
    return "" unless clue
    content_tag('td', clue['clue'], :class => 'clue') +
      content_tag('td', clue['prob'], :class => 'prob')
  end
end
