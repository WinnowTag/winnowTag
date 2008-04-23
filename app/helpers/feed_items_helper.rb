# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
module FeedItemsHelper
  include BiasSliderHelper
  STRIPPED_ELEMENTS = %w(script style link meta) unless const_defined?(:STRIPPED_ELEMENTS)
  
  def clean_html(html)
    unless html.blank? 
      doc = Hpricot(html)
      doc.search(STRIPPED_ELEMENTS.join(',')).each {|e| e.parent.children.delete(e) }
      doc.to_s
    end
  end
  
  def link_to_feed(feed, options = {})
    if feed.alternate 
      link_to(feed.title, feed.alternate, :target => "_blank") 
    else
      feed.title
    end
  end
  
  def link_to_feed_item(feed_item)
    if feed_item.link 
      link_to(feed_item.title, feed_item.link, :target => "_blank") 
    else
      feed_item.title
    end
  end
  
  def toggle_read_unread_button
    link_to_function "", "itemBrowser.toggleReadUnreadItem(this.up('.item'))", 
          # TODO: localization
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
    tags = feed_item.taggings_by_user(current_user, :tags => tags_to_display)
    current_user.subscribed_tags.group_by(&:user).map do |user|
      tags += feed_item.taggings_by_user(user, :tags => tags_to_display)
    end

    html = tags.sort_by { |tag, taggings| tag.name.downcase }.map do |tag, taggings|
      if tag.user == current_user
        tag_control_for(feed_item, tag, classes_for_taggings(taggings), format_classifier_strength(taggings))
      else
        if tagging = Array(taggings).first
          controls  = content_tag(:span, nil, :class => "status")
          controls << content_tag(:span, tag_training(tag), :class => "info")

          content   = content_tag(:span, h(tag.name), :class => "name")
          content  << content_tag(:span, controls, :class => "controls")

          content_tag(:li, content, :class => classes_for_taggings(tagging, [:public]).join(" "),
              :onmouseover => "set_tag_status(this, #{tag.name.to_json}, #{format_classifier_strength(taggings).to_json}, #{tag.user.display_name.to_json});")
        end
      end
    end.compact.join(" ")
    
    content_tag "ul", html, :class => "tag_list stop", :id => dom_id(feed_item, "tag_controls")
  end
  
  # Format a classifier tagging strength as a percentage.
  def format_classifier_strength(taggings)
    if classifier_tagging = taggings.detect {|t| t.classifier_tagging? }
      "%.2f%" % (classifier_tagging.strength * 100)
    end
  end
  
  def tags_to_display
    (current_user.sidebar_tags + current_user.subscribed_tags - current_user.excluded_tags + 
      Tag.find(:all, :conditions => ["tags.id IN(?) AND (public = ? OR user_id = ?)", params[:tag_ids].to_s.split(","), true, current_user])
    ).uniq
  end
  
  def tag_control_for(feed_item, tag, classes, classifier_strength)
    controls  = content_tag(:span, nil, :class => "status") << " "
    controls << link_to_function(_(:positive_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'positive')", :class => "positive") << " "
    controls << link_to_function(_(:negative_training_control), "add_tagging('#{dom_id(feed_item)}', #{tag.name.to_json}, 'negative')", :class => "negative") << " "
    controls << link_to_function(_(:remove_training_control),   "remove_tagging('#{dom_id(feed_item)}', #{tag.name.to_json})",          :class => "remove") << " "
    controls << content_tag(:span, tag_training(tag), :class => "info")

    content   = content_tag(:span, h(tag.name), :class => "name")
    content  << content_tag(:span, controls, :class => "controls")

    content_tag(:li, content, :id => dom_id(feed_item, "tag_control_for_#{tag.name}_on"), :class => classes.join(" "),
        :onmouseover => "set_tag_status(this, #{tag.name.to_json}, #{classifier_strength.to_json});")
  end
  
  def tag_training(tag)
    %|<dl>
      <dt>Training</dt>
      <dd>+#{tag.positive_count} / -#{tag.negative_count}</dd>
      <dt>Automatic</dt>
      <dd>#{tag.classifier_count}</dd>
    </dl>|
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
    if not feed_item.title.blank?
      feed_item.title
    else
      content_tag :span, _(:feed_item_no_title), :class => "notitle"
    end
  end
end
