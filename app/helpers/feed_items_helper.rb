# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module FeedItemsHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::TextHelper
  include BiasSliderHelper
  TAG_SEPARATOR = '&#32;<span class="tag_separator">&#8226;</span>&#32;' unless const_defined?(:TAG_SEPARATOR)
  STRIPPED_ELEMENTS = %w(script style link meta) unless const_defined?(:STRIPPED_ELEMENTS)
  
  def clean_html(html)
    unless html.blank? 
      doc = Hpricot(html)
      doc.search(STRIPPED_ELEMENTS.join(',')).each {|e| e.parent.children.delete(e) }
      doc.to_s
    end
  end
  
  def feed_link(feed_item, options = {})
    if feed_item.feed.alternate 
      link_to(feed_item.feed.title, feed_item.feed.alternate, options) 
    else
      feed_item.feed.title
    end
  end
  
  def toggle_read_unread_button
    link_to_function "", "itemBrowser.toggleReadUnreadItem(this.up('.item'))", 
          :onmouseover => "this.title = 'Click to mark as ' + ($(this).up('.item').match('.read') ? 'unread' : 'read');"
  end
  
  # Classification helpers
  # TODO: Remove if we are not using this, else update it to work with new filters
  def report_in_progress_classification
    #if current_user.classifier.current_job
    #  javascript_tag <<-END_JS
    #    classification = Classification.createItemBrowserClassification('/classifier');
    #    classification.startProgressUpdater();
    #  END_JS
    #end
  end
  
  # Creates the classification button.
  #
  # When pressed, the classification button creates a Classification
  # Javascript object that handles the interaction with the server.
  # See Classification and Classification.createItemBrowserClassification
  # in itembrowser.js.
  #
  # The way the routes are setup for the classifier controller means
  # that we can always identify a single classifier to use by either
  # a prefix path, as in the case of a tag publications classifier 
  # or using '/classifier' which is the classifier belonging
  # to the current user.
  #
  def classification_button
    display = ""
    #if current_user.classifier.current_job
    #  display = "display: none"
    #end
     
    classifier_path = "/classifier"
     
    button_to_function 'Start', :id => 'classification_button', :style => display do |page|
      page << <<-END_JS
         classification = Classification.createItemBrowserClassification(#{classifier_path.to_json});
         classification.start();
      END_JS
    end
  end
  
  # TODO: Remove if we are not using this, else update it to work with new filters
  def cancel_classification_button
    display = "display: none"
    #if current_user.classifier.current_job
    #  display = ""
    #end
    
    button_to_function("Stop", 'cancelClassification();', 
                        :style => display, 
                        :id => 'cancel_classification_button')
  end
  
  # TODO: Remove if we are not using this, else update it to work with new filters
  def classifier_progress_title
    "Classify changed tags"
  end
  
  # Prints each tag between a given user and taggable, including
  # tags assigned by classifiers on behalf of the user. Each tag will
  # be separated by TAG_SEPARATOR.
  #
  # * Users tags take precedence over classifier tags.
  #
  def display_tags_for(taggable)
    if show_manual_taggings?
      tags = taggable.taggings_by_user(current_user, :all_taggings => true, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : nil)
    else
      tags = taggable.taggings_by_user(current_user, :all_taggings => true)
    end
    
    tag_display = tags.collect do |tag, taggings|
      if tagging = Array(taggings).first
        content_tag('span', 
          h(tagging.tag.name), 
          :class => classes_for_taggings(tagging).join(" "))
      end
    end.compact

    current_user.subscribed_tags.group_by(&:user).each do |user, subscribed_tags|
      if show_manual_taggings?
        more_tags = taggable.taggings_by_user(user, :all_taggings => true, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : subscribed_tags)
      else
        more_tags = taggable.taggings_by_user(user, :all_taggings => true, :tags => subscribed_tags)
      end
            
      tag_display += more_tags.collect do |tag, taggings|
        if tagging = Array(taggings).first
          tag_name_with_tooltip(tag, :class => classes_for_taggings(tagging, [:public]).join(" "))
        end
      end.compact
    end
    
    html = if tag_display.empty?
      "<i>no tags</i>"
    else
      tag_display.join(TAG_SEPARATOR)
    end
    
    content_tag(:span, html, 
      :class => "tags", :id => dom_id(taggable, "open_tags"), 
      :onclick => "itemBrowser.toggleOpenCloseModerationPanel('#{dom_id(taggable)}'); Event.stop(event);")
  end
  
  def show_manual_taggings?
    params[:manual_taggings] =~ /true/i ? true : false 
  end
 
  # Builds tagging controls for a feed item
  #
  def tag_controls(feed_item, options = {})
    options[:hide] = Array(options[:hide])    
    if show_manual_taggings?
      tags = feed_item.taggings_by_user(current_user, :all_taggings => true, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : nil)
    else
      tags = feed_item.taggings_by_user(current_user, :all_taggings => true)
    end

    html = ""
    tags.each do |tag, taggings|
      content = content_tag("span", h(tag.name), :class => "name")
      content << content_tag("span", nil, :class => "add", :onclick => "add_tag('#{dom_id(feed_item)}', '#{escape_javascript(tag.name)}', true);", :onmouseover => "show_control_tooltip(this, this.parentNode, '#{escape_javascript(tag.name)}');")
      content << content_tag("span", nil, :class => "user")
      content << content_tag("span", nil, :class => "remove", :onclick => "remove_tag('#{dom_id(feed_item)}', '#{escape_javascript(tag.name)}');", :onmouseover => "show_control_tooltip(this, this.parentNode, '#{escape_javascript(tag.name)}');")
      classes = classes_for_taggings(taggings).join(' ')
      unless classes.blank?
        html << content_tag('li', content, 
          :id => dom_id(feed_item, "tag_control_for_#{tag.name}_on"), :class => classes, 
          :style => options[:hide].include?(tag.name) ? "display: none;" : nil, 
          :onmouseover => "show_tag_tooltip(this, '#{escape_javascript(tag.name)}');") + " "
      end
    end
    
    current_user.subscribed_tags.group_by(&:user).each do |user, subscribed_tags|
      if show_manual_taggings?
        more_tags = feed_item.taggings_by_user(user, :all_taggings => true, :tags => params[:tag_ids] ? params[:tag_ids].split(",") : subscribed_tags)
      else
        more_tags = feed_item.taggings_by_user(user, :all_taggings => true, :tags => subscribed_tags)
      end
      more_tags.collect do |tag, taggings|
        if tagging = Array(taggings).first
          tag_span = tag_name_with_tooltip(tag)
          html << content_tag(:li, tag_span, :class => classes_for_taggings(tagging, [:public, :name]).join(" "))
        end
      end
    end
    
    content_tag "ul", html, :class => "tag_list clearfix", :id => dom_id(feed_item, "tag_controls")
  end
  
  def unused_tag_controls(feed_item, options = {})
    options[:hide] = Array(options[:hide])    
    tags = feed_item.taggings_by_user(current_user, :all_taggings => true)

    unused_tags = []
    current_user.tags.each do |tag|      
      if taggings = tags.assoc(tag)
        # If it isn't a user tagging or a classifier tagging 
        # over 0.9 it hasn't been applied to the item.
        #
        # TODO: In Rails 2.0, Query caching will make this possible
        #       to do using the model objects without hitting the 
        #       database.
        #
        unless taggings.last.any? {|tagging| !tagging.classifier_tagging? || tagging.positive?}
          unused_tags << tag
        end
      else
        unused_tags << tag
      end
    end
    
    html = ""
    unused_tags.each do |tag|
      html << content_tag('li', content_tag("span", h(tag.name), :class => "name"),
        :id => dom_id(feed_item, "unused_tag_control_for_#{tag.name}_on"), :class => "cursor", 
        :style => options[:hide].include?(tag.name) ? "display: none;" : nil,
        :onclick => "add_tag('#{dom_id(feed_item)}', '#{escape_javascript(tag.name)}');", 
        :onmouseover => "show_tag_tooltip(this, '#{escape_javascript(tag.name)}');") + " "
    end
    content_tag "ul", html, :class => "tag_list clearfix", :id => dom_id(feed_item, "unused_tag_controls")
  end

	# Creates an array of CSS class names for a list of taggings.
	#
	def classes_for_taggings(taggings, classes = [])
	  taggings = Array(taggings)
    
    if taggings.size == 1 and tagging = taggings.first
      classes << tagging_type_class(tagging)      
      classes << "borderline" if tagging.borderline?
      
      if tagging.positive? or tagging.borderline?
        classes << "tagged"
      elsif !tagging.classifier_tagging?
        classes << "negative_tagging"
      else
        # revert to 'untagged' since we don't display negative taggings for classifiers
        classes = []
      end
    elsif taggings.size > 1
      classes += classes_for_taggings(taggings.first)
      
      # Add untagged classes for the remaining taggings
      taggings.last(taggings.size - 1).each do |tagging|
        classes << tagging_type_class(tagging)
      end
    end
    
    classes.uniq
  end

  def tagging_type_class(tagging)
    if tagging.classifier_tagging?
      "bayes_classifier_tagging"
    else
      "user_tagging"
    end
  end

  def link_to_feed_item(feed_item)
    feed_item.link ? link_to(feed_item.title, feed_item.link, :target => "_blank") : feed_item.title
  end
end
